#!/usr/bin/env python3
import urllib.request
import json
import sys

URL = "http://100.91.114.23:17580/sgv.json?count=1"

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
