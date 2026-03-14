# Blood Glucose Monitor - Plasma 6 & Zsh Integration

Un moniteur de glycémie en temps réel conçu pour **KDE Plasma 6** et **Zsh (Oh My Posh)**, optimisé pour fonctionner avec **Nightscout** ou **Juggluco** via un réseau **Tailscale**.

## 🚀 Fonctionnalités

- **Applet Plasma 6** :
    - Affichage direct de la glycémie et de la tendance dans votre tableau de bord.
    - Vue détaillée au clic avec **graphique historique** (dernières 2h).
    - **Alertes sonores et notifications** système en cas de glycémie critique (≤ 75 ou ≥ 250 mg/dL).
    - Vérification automatique de la connexion Tailscale avant chaque requête.
    - Code couleur dynamique (Vert/Orange/Rouge) selon les seuils.

- **Intégration Terminal (Oh My Posh)** :
    - Glycémie affichée directement dans votre prompt Zsh avec l'icône 🩸.
    - Couleurs adaptées au thème **Gruvbox Dark** (Orange/Marron).
    - Système de cache pour ne pas ralentir le terminal.

## 🛠️ Installation

### 1. Prérequis
- **Tailscale** installé et connecté.
- **KDE Plasma 6**.
- **Oh My Posh** (pour l'intégration terminal).
- **Python 3** (pour le script de prompt).

### 2. Configuration de l'Applet Plasma
```bash
# Cloner le dépôt et installer l'applet
kpackagetool6 -t Plasma/Applet --install .
```
Ensuite, ajoutez le composant graphique "Blood Glucose Monitor" à votre tableau de bord. Dans les paramètres, renseignez l'URL de votre serveur (ex: `http://100.x.y.z:17580`).

### 3. Configuration du Prompt Zsh
Ajoutez ce segment à votre fichier de configuration Oh My Posh (`.omp.json`) :
```json
{
  "type": "command",
  "style": "diamond",
  "background": "p:bg1",
  "foreground": "p:orange",
  "properties": {
    "command": "/chemin/vers/applet/bg_prompt.py",
    "cache_duration": "10s"
  },
  "template": " 🩸 {{ .Output }} "
}
```

## ⚙️ Architecture
- `contents/ui/main.qml` : Logique principale de l'applet Plasma 6.
- `contents/ui/FullRepresentation.qml` : Interface du graphique détaillé.
- `contents/code/logic.js` : Gestion des appels API vers Nightscout/Juggluco.
- `bg_prompt.py` : Script Python ultra-léger pour l'intégration terminal.

## 📝 Auteur
Développé par **rogissart**.
