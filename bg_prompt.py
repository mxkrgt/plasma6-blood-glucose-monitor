#!/usr/bin/env python3
import urllib.request
import json
import os
from pathlib import Path

# Détection du dossier du script pour trouver le .env
BASE_DIR = Path(__file__).resolve().parent
ENV_FILE = BASE_DIR / ".env"

def load_env():
    """Charge le .env manuellement pour rester léger."""
    if ENV_FILE.exists():
        with open(ENV_FILE) as f:
            for line in f:
                if "=" in line:
                    key, value = line.strip().split("=", 1)
                    os.environ[key] = value.strip('"').strip("'")

# Chargement initial
load_env()
SERVER_URL = os.getenv("BLOOD_GLUCOSE_SERVER", "http://100.x.y.z:17580")
URL = f"{SERVER_URL}/sgv.json?count=1"

def get_bg():
    try:
        with urllib.request.urlopen(URL, timeout=1.0) as response:
            data = json.loads(response.read().decode())
            if not data: return "0"
            latest = data[0]
            sgv = latest.get("sgv", 0)
            return str(sgv)
    except:
        return "0"

if __name__ == "__main__":
    print(get_bg())
