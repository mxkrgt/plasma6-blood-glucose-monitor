# Plasma 6 Blood Glucose Monitor

A real-time blood glucose monitor for **KDE Plasma 6** and **Zsh (Oh My Posh)**. Optimized for **Nightscout** or **Juggluco** via **Tailscale**.

## 🚀 Features

- **KDE Plasma 6 Applet**:
    - Real-time BG and trend arrow in your panel.
    - Expanded view with a **historical chart** (last 2 hours).
    - **Audio & Visual Notifications** for critical levels (Low ≤ 75, High ≥ 250 mg/dL).
    - Automatic **Tailscale connectivity check** before fetching data.

- **Terminal Integration (Oh My Posh)**:
    - Lightweight Python script to show your BG in your prompt.
    - Customizable colors and icons in your shell theme.
    - Efficient 10s cache to avoid network lag.

## 🛠️ Installation

### 1. Prerequisites
- **Tailscale** installed and connected.
- **KDE Plasma 6**.
- **Python 3**.

### 2. Configuration (Environment Variables)
Create a `.env` file in the root directory:
```bash
BLOOD_GLUCOSE_SERVER="http://100.x.y.z:17580"
```

### 3. Plasma Applet Setup
```bash
kpackagetool6 -t Plasma/Applet --install .
```
Add the "Blood Glucose Monitor" widget to your panel. Configure the server URL and thresholds in the settings UI.

### 4. Zsh / Oh My Posh Setup
Add a `command` segment to your Oh My Posh configuration file:
```json
{
  "type": "command",
  "style": "diamond",
  "background": "transparent",
  "foreground": "#ffffff",
  "properties": {
    "command": "/path/to/bg_prompt.py",
    "cache_duration": "10s"
  },
  "template": " 🩸 {{ .Output }} "
}
```

## 📝 Author
Developed by **rogissart**.
