#Requires -Version 5.1
<#
.SYNOPSIS
  Installe l'environnement de développement de base pour le Dojo Agentic Web (Windows).

.DESCRIPTION
  Équivalent Windows de setup-dojo-macos.sh : Git, Node.js (LTS), Firebase CLI, Cursor (optionnel),
  et création du dossier de travail %USERPROFILE%\dojo-agentic-web.

  Prérequis : Windows 10 (1809+) ou Windows 11 avec winget (App Installer).

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\setup-dojo-windows.ps1

.EXAMPLE
  $env:INSTALL_CURSOR = "0"; .\setup-dojo-windows.ps1
#>

param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$DOJO_DIR = Join-Path $env:USERPROFILE "dojo-agentic-web"
if (-not $env:INSTALL_CURSOR) {
  $env:INSTALL_CURSOR = "1"
}

function Write-LogStep {
  param([string]$Message)
  Write-Host ""
  Write-Host "==> $Message" -ForegroundColor Cyan
}

function Write-WarnStep {
  param([string]$Message)
  Write-Host ""
  Write-Host $Message -ForegroundColor Yellow
}

function Test-CommandExists {
  param([string]$Name)
  return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

# Runs a native command (npm, winget, etc.) without letting stderr output
# trigger PowerShell's NativeCommandError under $ErrorActionPreference = "Stop".
# Streams stdout+stderr to the host as plain text and validates $LASTEXITCODE.
function Invoke-NativeCli {
  param(
    [Parameter(Mandatory = $true)][scriptblock]$ScriptBlock,
    [string]$ErrorMessage = "Command failed"
  )

  $previousPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  $exit = 0
  try {
    & $ScriptBlock 2>&1 | ForEach-Object { Write-Host $_ }
    if ($null -ne $LASTEXITCODE) {
      $exit = $LASTEXITCODE
    }
  }
  finally {
    $ErrorActionPreference = $previousPreference
  }

  if ($exit -ne 0) {
    throw "$ErrorMessage (exit code $exit)"
  }
}

function Update-SessionPath {
  $machine = [Environment]::GetEnvironmentVariable("Path", "Machine")
  $user = [Environment]::GetEnvironmentVariable("Path", "User")
  $env:Path = "$machine;$user"
}

function Ensure-Windows {
  if ($env:OS -ne "Windows_NT") {
    Write-Host "Ce script est prévu pour Windows."
    exit 1
  }
}

function Ensure-Winget {
  Write-LogStep "Vérification de winget"
  if (-not (Test-CommandExists "winget")) {
    Write-WarnStep "winget introuvable. Installez « App Installer » depuis le Microsoft Store, puis relancez ce script."
    exit 1
  }
  Write-Host "winget disponible."
}

function Invoke-WingetInstall {
  param(
    [Parameter(Mandatory = $true)][string]$Id,
    [Parameter(Mandatory = $true)][string]$Label
  )

  Write-LogStep "Installation via winget : $Label ($Id)"
  $block = {
    & winget install --id $Id -e --accept-source-agreements --accept-package-agreements --disable-interactivity
  }.GetNewClosure()
  Invoke-NativeCli -ErrorMessage "winget install $Id a échoué" -ScriptBlock $block
  Update-SessionPath
}

function Ensure-Git {
  if (Test-CommandExists "git") {
    Write-Host "Git déjà disponible."
    return
  }
  Invoke-WingetInstall -Id "Git.Git" -Label "Git"
  Update-SessionPath
  if (-not (Test-CommandExists "git")) {
    Write-WarnStep "Git installé mais introuvable dans le PATH. Fermez et rouvrez le terminal, puis relancez ce script."
    exit 1
  }
}

function Ensure-Node {
  if (Test-CommandExists "node") {
    Write-Host "Node.js déjà disponible."
    return
  }
  Invoke-WingetInstall -Id "OpenJS.NodeJS.LTS" -Label "Node.js LTS"
  Update-SessionPath
  if (-not (Test-CommandExists "node")) {
    Write-WarnStep "Node.js installé mais introuvable dans le PATH. Fermez et rouvrez le terminal, puis relancez ce script."
    exit 1
  }
}

function Add-UserPathEntry {
  param([string]$Directory)

  if (-not (Test-Path $Directory)) {
    New-Item -ItemType Directory -Path $Directory -Force | Out-Null
  }

  $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
  if ($userPath -notlike "*${Directory}*") {
    $newPath = if ([string]::IsNullOrEmpty($userPath)) { $Directory } else { "$userPath;$Directory" }
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host "PATH utilisateur mis à jour : $Directory"
  }
  Update-SessionPath
}

function Ensure-NpmGlobal {
  param(
    [Parameter(Mandatory = $true)][string]$BinaryName,
    [Parameter(Mandatory = $true)][string]$PackageName
  )

  if (Test-CommandExists $BinaryName) {
    Write-Host "$BinaryName déjà installé."
    return
  }

  Write-Host "Installation de $PackageName..."
  $installBlock = { & npm install -g $PackageName }.GetNewClosure()
  Invoke-NativeCli -ErrorMessage "npm install -g $PackageName a échoué" -ScriptBlock $installBlock
  Update-SessionPath

  if (Test-CommandExists $BinaryName) {
    return
  }

  Write-WarnStep "Installation globale npm échouée ou $BinaryName absent du PATH. Configuration d'un préfixe utilisateur npm."

  $npmPrefix = Join-Path $env:USERPROFILE ".npm-global"
  New-Item -ItemType Directory -Path $npmPrefix -Force | Out-Null
  $prefixBlock = { & npm config set prefix $npmPrefix }.GetNewClosure()
  Invoke-NativeCli -ErrorMessage "npm config set prefix a échoué" -ScriptBlock $prefixBlock

  # Sur Windows, les binaires npm globaux vivent directement dans le préfixe
  # (pas dans un sous-dossier bin/ comme sous Unix). `npm bin -g` a été
  # supprimé en npm 9+, on ne peut donc plus s'appuyer dessus.
  $npmGlobalBin = $npmPrefix
  Add-UserPathEntry -Directory $npmGlobalBin
  $env:Path = "$npmGlobalBin;$env:Path"

  Invoke-NativeCli -ErrorMessage "npm install -g $PackageName a échoué" -ScriptBlock $installBlock
  Update-SessionPath

  if (-not (Test-CommandExists $BinaryName)) {
    Write-Host "Échec de l'installation npm globale de $PackageName (préfixe $npmPrefix)."
    exit 1
  }
}

function Ensure-FirebaseCli {
  Ensure-NpmGlobal -BinaryName "firebase" -PackageName "firebase-tools@latest"
  if (-not (Test-CommandExists "firebase")) {
    Write-Host "Firebase CLI installé, mais la commande firebase n'est pas disponible dans le PATH."
    Write-Host "Fermez et rouvrez le terminal, puis relancez ce script."
    exit 1
  }
}

function Test-CursorInstalled {
  $pf = [Environment]::GetFolderPath("ProgramFiles")
  $pfx86 = [Environment]::GetFolderPath("ProgramFilesX86")
  $candidates = @(
    (Join-Path $env:LOCALAPPDATA "Programs\cursor\Cursor.exe"),
    (Join-Path $pf "Cursor\Cursor.exe"),
    (Join-Path $pfx86 "Cursor\Cursor.exe")
  )
  foreach ($p in $candidates) {
    if (Test-Path -LiteralPath $p) {
      return $true
    }
  }
  return $false
}

function Ensure-Cursor {
  if ($env:INSTALL_CURSOR -ne "1") {
    return
  }

  if (Test-CursorInstalled) {
    Write-Host "Cursor déjà installé."
    return
  }

  Invoke-WingetInstall -Id "Anysphere.Cursor" -Label "Cursor"
  Update-SessionPath

  if (-not (Test-CursorInstalled)) {
    Write-WarnStep "Cursor n'a pas été détecté aux emplacements habituels. Vérifiez l'installation manuelle si besoin."
  }
}

function New-DojoWorkspace {
  Write-LogStep "Création du dossier de travail"

  New-Item -ItemType Directory -Path $DOJO_DIR -Force | Out-Null

  $readme = @'
# Dojo Agentic Web

Pendant l'atelier, nous créerons une app web locale avec :

- React + Vite
- Firebase Authentication
- Google Sign-In
- Firestore
- un agent de développement

Commandes de départ pendant le dojo (PowerShell) :

```powershell
cd $env:USERPROFILE\dojo-agentic-web
firebase login
npm create vite@latest feedback-wall -- --template react
cd feedback-wall
npm install
npm run dev
```
'@

  $readme | Set-Content -Path (Join-Path $DOJO_DIR "README_DOJO.md") -Encoding UTF8
  Write-Host "Dossier prêt : $DOJO_DIR"
}

function Show-FinalCheck {
  Write-LogStep "Vérification finale"

  Write-Host ("Git: " + (& git --version))
  Write-Host ("Node: " + (& node -v))
  Write-Host ("npm: " + (& npm -v))
  Write-Host ("Firebase: " + (& firebase --version))

  if ($env:INSTALL_CURSOR -eq "1") {
    if (Test-CursorInstalled) {
      Write-Host "Cursor: installé"
    }
    else {
      Write-Host "Cursor: non détecté (vérifiez le raccourci ou le menu Démarrer)"
    }
  }

  Write-Host ""
  Write-Host "Environnement prêt."
  Write-Host ""
  Write-Host "À lancer pendant le dojo :"
  Write-Host "  cd `$env:USERPROFILE\dojo-agentic-web"
  Write-Host "  firebase login"
  Write-Host "  npm create vite@latest feedback-wall -- --template react"
}

function Main {
  Ensure-Windows
  Ensure-Winget

  Write-LogStep "Installation des outils de base"
  Ensure-Git
  Ensure-Node

  Write-LogStep "Installation des outils Firebase et agentiques"
  Ensure-FirebaseCli

  if ($env:INSTALL_CURSOR -eq "1") {
    Ensure-Cursor
  }

  New-DojoWorkspace
  Show-FinalCheck
}

Main
