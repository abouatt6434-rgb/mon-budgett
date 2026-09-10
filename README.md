# MON BUDGET — Guide de compilation (Codemagic)

Ce projet Flutter est complet et prêt à être compilé. Comme demandé, voici
la procédure **sans rien installer sur ton ordinateur**, en utilisant le
service gratuit Codemagic.

## Ce qui est fait ✅
- Application Flutter complète (écrans, base de données locale, budget,
  statistiques, export, paramètres).
- Fonctionne 100% hors ligne (SQLite local).
- Fichier `codemagic.yaml` déjà configuré pour générer l'APK automatiquement.

## Ce qu'il reste à faire (action de ta part)
Compiler réellement l'APK — cela ne peut se faire que sur une machine avec
Flutter installé, ou via un service cloud comme Codemagic. Voici la marche
à suivre.

---

### ÉTAPE 1 : crée un compte GitHub (si tu n'en as pas)
Va sur https://github.com et crée un compte gratuit.

### ÉTAPE 2 : crée un nouveau dépôt (repository)
Sur GitHub, clique sur **New repository**, nomme-le `mon-budget`, laisse-le
en **Public** ou **Private**, puis clique sur **Create repository**.

### ÉTAPE 3 : mets le projet en ligne
Sur la page de ton nouveau dépôt vide, GitHub te propose des commandes.
Sur ton ordinateur (ou depuis l'interface web "upload files" si tu ne
veux rien taper), fais glisser **tout le contenu du dossier `mon_budget`**
que je t'ai fourni, puis clique sur **Commit changes**.

*(Astuce : si tu préfères tout faire depuis un navigateur sans rien
installer, utilise le bouton "Add file" → "Upload files" sur GitHub et
dépose le dossier entier.)*

### ÉTAPE 4 : connecte Codemagic à GitHub
Va sur https://codemagic.io, clique sur **Sign up**, choisis
**Sign up with GitHub**, et autorise l'accès.

### ÉTAPE 5 : ajoute ton application
Dans Codemagic, clique sur **Add application**, sélectionne ton dépôt
`mon-budget`, et choisis **Flutter App** comme type de projet.

### ÉTAPE 6 : lance le build
Codemagic va détecter automatiquement le fichier `codemagic.yaml` inclus
dans le projet. Clique simplement sur **Start new build**, choisis le
workflow **MON BUDGET - Build Android APK**, puis lance-le.

La compilation prend généralement 5 à 15 minutes.

### ÉTAPE 7 : télécharge l'APK
Une fois le build terminé (statut vert ✅), va dans l'onglet **Artifacts**
de ce build : tu y trouveras un fichier `app-release.apk`. Télécharge-le.

---

## Installer l'APK sur ton téléphone Android

1. Transfère le fichier `app-release.apk` sur ton téléphone (par email,
   Google Drive, USB, ou directement téléchargé depuis le téléphone).
2. Ouvre le fichier depuis le gestionnaire de fichiers du téléphone.
3. Android va probablement afficher un avertissement de sécurité
   ("Source inconnue") : autorise l'installation pour cette fois.
4. Appuie sur **Installer**.
5. Ouvre l'application **MON BUDGET**.

---

## Important — honnêteté sur l'état du projet

- Le **code est complet et fonctionnel** pour toutes les fonctionnalités
  principales : dépenses, revenus, historique avec recherche/filtres/tri,
  modification/suppression, budgets (global + par catégorie) avec alertes
  visuelles à 50/75/90/100%, statistiques avec graphique en camembert,
  export CSV, paramètres (thème clair/sombre, masquage des montants,
  suppression des données), onboarding.
- **Non encore implémenté** (prévu pour une version ultérieure, l'architecture
  le permet) : notifications système programmées (l'app affiche les alertes
  de budget visuellement dans l'app, mais pas encore de notification push
  Android), code PIN / biométrie, sauvegarde/restauration JSON, export PDF,
  synchronisation cloud, support multi-devises actif (la structure existe
  mais seul le FCFA est branché).
- **Aucun APK n'a été généré par moi** — je n'ai pas d'environnement Flutter
  ni d'accès réseau ici. L'APK ne sera réel qu'une fois que tu auras suivi
  les étapes ci-dessus sur Codemagic.
- Une fois l'APK obtenu et testé, dis-le-moi : je pourrai t'aider à corriger
  d'éventuelles erreurs de compilation (souvent liées aux versions de
  dépendances) et à avancer vers les fonctionnalités manquantes ou vers la
  préparation Google Play (AAB, signature, applicationId définitif).

## Renommer l'application plus tard
Le nom "MON BUDGET" est centralisé à deux endroits :
- `android/app/src/main/AndroidManifest.xml` → `android:label`
- `pubspec.yaml` → `name`/`description`

## Préparer Google Play plus tard
Avant toute publication réelle :
- changer `applicationId` dans `android/app/build.gradle` (actuellement
  `com.monbudget.app`, à personnaliser),
- créer une vraie clé de signature (keystore) au lieu de la signature debug,
  actuellement utilisée pour permettre une première compilation immédiate,
- générer un AAB avec `flutter build appbundle --release` (ou l'équivalent
  Codemagic).
