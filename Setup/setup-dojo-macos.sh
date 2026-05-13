#!/usr/bin/env bash
set -euo pipefail

DOJO_DIR="${HOME}/Documents/dojo-agentic-web"

# Mettre à 0 si vous ne voulez pas installer Cursor automatiquement.
INSTALL_CURSOR="${INSTALL_CURSOR:-1}"

log() {
  printf "\n\033[1m==> %s\033[0m\n" "$1"
}

warn() {
  printf "\n\033[33m%s\033[0m\n" "$1"
}

has_command() {
  command -v "$1" >/dev/null 2>&1
}

ensure_macos() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "Ce script est prévu pour macOS."
    echo "Pour Windows ou Linux, prévoir un script séparé."
    exit 1
  fi
}

ensure_xcode_command_line_tools() {
  log "Vérification des Command Line Tools Apple"

  if xcode-select -p >/dev/null 2>&1; then
    echo "Command Line Tools déjà installés."
    return
  fi

  warn "Command Line Tools Apple non installés."
  echo "Une fenêtre macOS va probablement s'ouvrir pour lancer l'installation."
  echo "Acceptez l'installation, puis relancez ce script une fois terminée."

  xcode-select --install || true
  exit 1
}

ensure_homebrew() {
  log "Vérification de Homebrew"

  if has_command brew; then
    echo "Homebrew déjà installé."
  else
    echo "Installation de Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  # Ajout de brew au PATH pour la session courante.
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  if ! has_command brew; then
    echo "Homebrew semble installé, mais n'est pas disponible dans le PATH."
    echo "Fermez et rouvrez le terminal, puis relancez le script."
    exit 1
  fi

  # Ajout durable au shell zsh, shell par défaut sur macOS récent.
  BREW_BIN="$(command -v brew)"
  BREW_SHELLENV_LINE="eval \"\$(${BREW_BIN} shellenv)\""

  touch "${HOME}/.zprofile"
  if ! grep -qs "brew shellenv" "${HOME}/.zprofile"; then
    echo "" >> "${HOME}/.zprofile"
    echo "# Homebrew" >> "${HOME}/.zprofile"
    echo "${BREW_SHELLENV_LINE}" >> "${HOME}/.zprofile"
  fi

  brew update
}

ensure_brew_formula() {
  local package="$1"

  if brew list --formula "$package" >/dev/null 2>&1; then
    echo "$package déjà installé."
  else
    echo "Installation de $package..."
    brew install "$package"
  fi
}

ensure_brew_cask() {
  local cask="$1"
  local app_name="${2:-}"

  if brew list --cask "$cask" >/dev/null 2>&1; then
    echo "$cask déjà installé (Homebrew)."
  elif [[ -n "$app_name" && -d "/Applications/${app_name}.app" ]]; then
    echo "$cask déjà installé (manuel)."
  else
    echo "Installation de $cask..."
    brew install --cask "$cask"
  fi
}

ensure_npm_global() {
  local binary="$1"
  local package="$2"

  if has_command "$binary"; then
    echo "$binary déjà installé."
    return
  fi

  echo "Installation de $package..."

  if npm install -g "$package" && has_command "$binary"; then
    return
  fi

  warn "Installation globale npm échouée ou $binary absent du PATH. Configuration d'un préfixe utilisateur npm."

  mkdir -p "${HOME}/.npm-global"
  npm config set prefix "${HOME}/.npm-global"

  touch "${HOME}/.zprofile"
  if ! grep -qs ".npm-global/bin" "${HOME}/.zprofile"; then
    echo "" >> "${HOME}/.zprofile"
    echo "# npm global packages" >> "${HOME}/.zprofile"
    echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "${HOME}/.zprofile"
  fi

  export PATH="${HOME}/.npm-global/bin:${PATH}"
  if ! npm install -g "$package"; then
    echo "Échec de l'installation npm globale de $package (préfixe ~/.npm-global)."
    echo "Consultez les messages d'erreur npm ci-dessus."
    exit 1
  fi

  if ! has_command "$binary"; then
    echo "$package semble installé, mais la commande $binary est toujours introuvable dans le PATH."
    echo "Vérifiez la sortie de npm ci-dessus. Fermez et rouvrez le terminal si le PATH a été mis à jour dans ~/.zprofile."
    exit 1
  fi
}

ensure_firebase_cli() {
  ensure_npm_global firebase firebase-tools@latest

  if ! has_command firebase; then
    echo "Firebase CLI installé, mais la commande firebase n'est pas disponible dans le PATH."
    echo "Fermez et rouvrez le terminal, puis relancez le script."
    exit 1
  fi
}

create_workspace() {
  log "Création du dossier de travail"

  mkdir -p "$DOJO_DIR"

  cat > "${DOJO_DIR}/README_DOJO.md" <<'EOF'
# Dojo Agentic Web

Pendant l'atelier, nous créerons une app web locale avec :

- React + Vite
- Firebase Authentication
- Google Sign-In
- Firestore
- un agent de développement

Commandes de départ pendant le dojo :

```bash
cd ~/Documents/dojo-agentic-web
firebase login
npm create vite@latest feedback-wall -- --template react
cd feedback-wall
npm install
npm run dev
```
EOF
  echo "Dossier prêt : ${DOJO_DIR}"
}

final_check() {
  log "Vérification finale"

  echo "Git: $(git --version)"
  echo "Node: $(node -v)"
  echo "npm: $(npm -v)"
  echo "Firebase: $(firebase --version)"

  if [[ "$INSTALL_CURSOR" == "1" ]]; then
    if [[ -d "/Applications/Cursor.app" ]]; then
      echo "Cursor: installé"
    else
      echo "Cursor: non trouvé dans /Applications"
    fi
  fi

  echo ""
  echo "Environnement prêt."
  echo ""
  echo "À lancer pendant le dojo :"
  echo "cd ~/Documents/dojo-agentic-web"
  echo "firebase login"
  echo "npm create vite@latest feedback-wall -- --template react"
}

main() {
  ensure_macos
  ensure_xcode_command_line_tools
  ensure_homebrew

  log "Installation des outils de base"
  ensure_brew_formula git
  ensure_brew_formula node

  log "Installation des outils Firebase et agentiques"
  ensure_firebase_cli

  if [[ "$INSTALL_CURSOR" == "1" ]]; then
    ensure_brew_cask cursor "Cursor"
  fi

  create_workspace
  final_check
}

main "$@"
