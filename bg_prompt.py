#!/usr/bin/env python3
import urllib.request
import urllib.error
import json
import os
import hashlib

NIGHTSCOUT_URL = os.getenv("NIGHTSCOUT_URL", "https://diabetemaxime.duckdns.org")
NIGHTSCOUT_API_SECRET = os.getenv("NIGHTSCOUT_API_SECRET", "")

def get_api_secret_hash():
    return hashlib.sha1(NIGHTSCOUT_API_SECRET.encode()).hexdigest()

def get_bg():
    try:
        url = NIGHTSCOUT_URL.rstrip("/") + "/api/v1/entries/sgv.json?count=1"
        req = urllib.request.Request(url)
        req.add_header("API-SECRET", get_api_secret_hash())
        with urllib.request.urlopen(req, timeout=2.0) as response:
            data = json.loads(response.read().decode())
            if not data:
                return "0"
            latest = data[0]
            sgv = latest.get("sgv", 0)
            direction = latest.get("direction", "")
            arrows = {
                "DoubleUp": "⇈", "SingleUp": "↑", "FortyFiveUp": "↗",
                "Flat": "→", "FortyFiveDown": "↘", "SingleDown": "↓",
                "DoubleDown": "⇊",
            }
            arrow = arrows.get(direction, "")
            return f"{sgv}{arrow}"
    except Exception:
        return "0"

if __name__ == "__main__":
    print(get_bg())
