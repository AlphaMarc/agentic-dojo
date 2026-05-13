# Dojo Agentique

Le défi d'une session de 60 minutes, c'est le scope creep. Pour le gérer, cette feuille de progression se concentre sur des jalons fonctionnels plutôt que sur des fonctionnalités précises. Elle considère Cursor comme "l'équipe d'ingénierie" et le PM comme le "Tech Lead".

## Le Dojo "Founder" en 60 minutes

L'objectif : transformer votre idée produit en MVP déployé avec Cursor, React et Firebase.

## Avant de lancer le chrono

Préparez ces éléments en amont, avant de démarrer le sprint de 60 minutes.

- [ ] Vérifier la bonne installation des prérequis

```bash
bash ./Setup/setup-deojo-macos.sh
```

- [ ] Se connecter à Firebase avec la dernière version du Firebase CLI :

```bash
npx -y firebase-tools@latest login
```

Si la connexion via navigateur ne s'ouvre pas correctement, utilisez :

```bash
npx -y firebase-tools@latest login --no-localhost
```

- [ ] Vérifier l'accès au Firebase CLI :

```bash
npx -y firebase-tools@latest --version
npx -y firebase-tools@latest projects:list
```

- [ ] Copier-coller ce prompt dans Cursor pour préparer le projet :

```text
Prépare mon projet pour le Dojo.

1. Demande-moi le nom de mon produit.
2. À partir de ce nom, propose un nom de dossier local clair et un Firebase Project ID compatible avec Firebase : minuscules, chiffres et tirets uniquement, sans espaces. Le Project ID doit être unique, donc ajoute un suffixe aléatoire court.
3. Crée un dossier local avec ce nom pour contenir tous les fichiers du projet.
4. Place-toi dans ce dossier.
5. Initialise un dépôt Git avec git init.
6. Vérifie que je suis connecté à Firebase avec npx -y firebase-tools@latest projects:list. Si je ne suis pas connecté, lance npx -y firebase-tools@latest login et attends que je termine.
7. Crée un nouveau projet Firebase avec ce nom en utilisant npx -y firebase-tools@latest projects:create.
8. Crée un fichier firebase.json puis associe ce projet Firebase au dossier local avec npx -y firebase-tools@latest use --add.
9. Active les services firebase dont nous auront besoin sur la région Europe. Utilise uniquement la CLI firebase, n'utilise en aucun cas la cli google cloud : 
    9.1 : authentification avec google uniquement, 
    9.2 : firestore database, active l'API firebase et initialise avec une collection test puis vérifie sa présence pour valider la bonne initialisation. Crée également index et rules de base.
    9.3 : website hosting classic, crée une petite page web toute simple "dojo cursor PM" puis déploie là et vérifie le bon déploiement
10. À la fin, affiche le chemin du dossier, le nom du projet Firebase, le Project ID Firebase et les prochaines étapes manuelles à faire dans la Firebase Console.
11. Fais un premier commit sur le repo git

Avant chaque commande qui crée ou modifie quelque chose, explique rapidement ce que tu vas faire.
```

- [ ] Préparer un compte Google `@betomorrow.com` pour tester le cas nominal de connexion.
- [ ] Préparer un compte Google hors `@betomorrow.com` pour vérifier que l'accès est bien bloqué.
- [ ] Décider si le groupe déploiera sur Vercel ou Firebase Hosting.


## Le chrono du sprint

| Temps | Phase | Rôle du PM | Action clé dans Cursor |
| --- | --- | --- | --- |
| 0-10m | Le Blueprint | Définir le périmètre du MVP | Composer (`Cmd + I`) |
| 10-30m | La construction UI | Relire et réorienter le design | Edit Mode (`Cmd + K`) |
| 30-40m | La porte d'accès | Protéger le MVP | Firebase Console + Auth |
| 40-50m | La logique | Orchestrer données et IA | Références de contexte (`@`) |
| 50-60m | La livraison | QA et déploiement | Terminal + déploiement |

## Barre de progression

`[                    ] 0%`

## Checklists de mission

### 1. Le Blueprint

Temps : 0-10m

Objectif : dire à l'IA quoi construire. Ne soyez pas vague.

- [ ] Ouvrir un dossier vide dans Cursor.
- [ ] Action Cursor : ouvrir Composer (`Cmd + I`) et décrire votre idée avec ce canevas :

```text
Je veux construire [Nom du produit]. C'est un outil pour [Audience cible] qui résout [Problème]. Utilise React, Tailwind CSS et Lucide-react pour les icônes. Crée une interface de dashboard claire et moderne.
```

- [ ] Vérification : est-ce que `npm start` affiche une interface qui correspond à votre vision ?

### 2. La construction UI

Temps : 10-30m

Objectif : afficher les "Inputs" et les "Outputs" à l'écran.

- [ ] Identifier votre fonctionnalité "North Star", la chose que l'application doit absolument faire.
- [ ] Action Cursor : surligner une section de la page et utiliser `Cmd + K` :

```text
Ajoute ici un formulaire pour capturer [Input utilisateur] et une belle carte en dessous pour afficher [Résultat/Output].
```

- [ ] Vérification : pouvez-vous saisir du texte dans les champs ? Est-ce que cela ressemble à une vraie application ?

### 3. La porte d'accès

Temps : 30-40m

Objectif : ajouter l'authentification Google et limiter l'accès aux adresses email `@betomorrow.com`.

Étapes manuelles à faire dans la Firebase Console, car Cursor ne peut pas tout faire via le Firebase CLI :

- [ ] Ouvrir la [Firebase Console](https://console.firebase.google.com/) et sélectionner votre projet.
- [ ] Aller dans **Authentication** > **Get started** si Authentication n'est pas encore activé.
- [ ] Aller dans **Sign-in method** > **Google**.
- [ ] Activer le fournisseur Google.
- [ ] Renseigner le nom public du projet.
- [ ] Sélectionner une adresse email de support pour le projet.
- [ ] Enregistrer la configuration du fournisseur.
- [ ] Aller dans **Authentication** > **Settings** > **Authorized domains**.
- [ ] Ajouter le domaine déployé, par exemple `your-app.vercel.app`, s'il n'est pas déjà listé.
- [ ] Garder `localhost` autorisé pendant le développement local.

Ensuite, demandez à Cursor de câbler l'application :

```text
Ajoute Firebase Authentication avec une connexion Google. Autorise uniquement les utilisateurs dont l'adresse email vérifiée se termine par @betomorrow.com. Si un autre utilisateur se connecte, déconnecte-le immédiatement et affiche un message d'erreur clair. Masque l'application tant qu'un utilisateur autorisé n'est pas authentifié.
```

Si l'application sauvegarde des données dans Firestore, demandez aussi à Cursor :

```text
Mets à jour les règles de sécurité Firestore pour que les lectures et écritures exigent request.auth, une adresse email vérifiée et une adresse email qui se termine par @betomorrow.com.
```

- [ ] Vérification : est-ce qu'un compte `@betomorrow.com` peut entrer dans l'application ?
- [ ] Vérification : est-ce qu'un compte hors `@betomorrow.com` est rejeté ?
- [ ] Vérification : est-ce que l'URL déployée est bien ajoutée aux domaines autorisés Firebase ?

Important : la Firebase Console active la connexion Google, mais la restriction `@betomorrow.com` doit être appliquée dans la logique de l'application et dans les règles de sécurité Firebase.

### 4. La logique et la "magie"

Temps : 40-50m

Objectif : connecter les boutons au cerveau (LLM) et à la mémoire (Firebase).

- [ ] Le cerveau : si votre application a besoin de logique IA, utilisez `Cmd + L` (Chat) :

```text
Écris une fonction dans App.js qui envoie l'input utilisateur à l'API OpenAI et retourne une réponse structurée basée sur [Votre logique spécifique].
```

- [ ] La mémoire : utilisez `@Firebase` en référençant votre configuration :

```text
Quand l'utilisateur clique sur "Save", enregistre ce résultat dans une collection Firestore pour qu'il ne le perde pas.
```

- [ ] Vérification : est-ce que cliquer sur le bouton déclenche réellement l'action attendue ?

### 5. La livraison

Temps : 50-60m

Objectif : mettre l'application sur Internet.

- [ ] Nettoyage : utilisez Cursor Chat :

```text
Audite ce code pour trouver les erreurs et supprime tout texte "lorem ipsum".
```

- [ ] Déploiement : demandez à Cursor :

```text
Aide-moi à déployer ce projet sur Vercel ou Firebase Hosting maintenant. Donne-moi les commandes terminal.
```

- [ ] Démo : partagez votre URL en ligne.

## Méta-prompts du Dojo

Copiez-collez ces prompts pendant la session.

Pour obtenir une meilleure UI :

```text
Ça ressemble trop à du "Bootstrap". Fais en sorte que l'interface soit plus moderne, inspirée de Linear ou Stripe, avec de bons espacements et des bordures subtiles.
```

Pour corriger un bug :

```text
J'obtiens cette erreur : [Coller l'erreur]. Regarde @App.js et corrige la logique.
```

Pour ajouter une fonctionnalité que vous ne savez pas coder :

```text
Je suis PM, pas développeur. Je veux ajouter un bouton "Télécharger en PDF". Écris le code et dis-moi où le mettre.
```

## Graduation ceinture noire

Vous avez réussi quand vous pouvez montrer au Sensei :

- Un input fonctionnel : vous pouvez saisir des données.
- Le moment "magique" : l'application traite ces données, via l'IA ou de la logique.
- Un lien en ligne : l'application existe en dehors de votre ordinateur.

## Stratégie pour le Sensei

- Minute 15 : faites le tour de la salle. Si un PM n'a pas encore d'UI visible, dites-lui d'utiliser Composer pour "simplement construire le layout d'abord".
- Minute 40 : rappelez-leur de se concentrer sur une seule fonctionnalité. "Si votre app fait cinq choses, choisissez la plus intéressante et terminez-la."
- Minute 55 : forcez tout le monde à lancer la commande de déploiement, même si l'application est "moche". Livré vaut mieux que parfait.
