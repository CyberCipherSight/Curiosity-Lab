#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# Stick War: Legacy save inspector for the tested 2026.1.1196 format.
# Requirements: rooted Android + Termux + Python 3 + pycryptodome.
# Read-only: copies the live PlayerPrefs file to Termux, then inspects it locally.

PKG='com.maxgames.stickwarlegacy'
TARGET="/data/user/0/$PKG/shared_prefs/$PKG.v2.playerprefs.xml"
MIRROR='42dcb5dc012d50f2f334b9d105889a292e3c3ce5'
AES_KEY='471f58d72fd273ds47c49f9e481cabe3'
OUTDIR="$HOME/game-save-backups/stick-war-legacy"
STAMP="$(date +%Y%m%d-%H%M%S)"
SNAP="$OUTDIR/playerprefs-$STAMP.xml"
mkdir -p "$OUTDIR"

su -c 'id' >/dev/null
su -c "cat '$TARGET'" > "$SNAP"

python - "$SNAP" "$MIRROR" "$AES_KEY" <<'PY'
import base64, json, sys, urllib.parse, xml.etree.ElementTree as ET
from Crypto.Cipher import AES
from Crypto.Util.Padding import unpad

path, mirror_name, key_s = sys.argv[1:]
root = ET.parse(path).getroot()

def pref(name):
    node = root.find(f".//*[@name='{name}']")
    if node is None:
        raise SystemExit(f"Missing PlayerPrefs entry: {name}")
    return node

items = pref("items").text or ""
if items.lstrip().lower().startswith("%7b"):
    items = urllib.parse.unquote(items)
plain = json.loads(items)
ledger = plain.get("distributedGems", {})
print("Snapshot:", path)
print("Legacy gems:", plain.get("gems"))
print("Distributed gems sum:", sum(int(v) for v in ledger.values()) if isinstance(ledger, dict) else "unavailable")

mirror = urllib.parse.unquote(pref(mirror_name).text or "")
ciphertext = base64.b64decode(mirror)
mirror_json = unpad(AES.new(key_s.encode("ascii"), AES.MODE_ECB).decrypt(ciphertext), AES.block_size).decode("utf-8")
print("Plain/encrypted mirror match:", mirror_json == items)
print("Device/install-specific ledger IDs are intentionally not printed.")
PY
