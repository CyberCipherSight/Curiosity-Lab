#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# Iron Marines RTS Offline save inspector for the tested 1.9.20 format.
# Requirements: rooted Android + Termux + Python 3.
# Read-only: copies the live PlayerPrefs file to Termux and decodes the save locally.

PKG='com.ironhidegames.android.ironmarines'
TARGET="/data/user/0/$PKG/shared_prefs/$PKG.v2.playerprefs.xml"
SAVE_KEY='Ironmarines.Savegames.com.ironhidegames.ironmarines.savegame'
OUTDIR="$HOME/game-save-backups/iron-marines"
STAMP="$(date +%Y%m%d-%H%M%S)"
SNAP="$OUTDIR/playerprefs-$STAMP.xml"
mkdir -p "$OUTDIR"

su -c 'id' >/dev/null
su -c "cat '$TARGET'" > "$SNAP"

python - "$SNAP" "$SAVE_KEY" <<'PY'
import json, sys, urllib.parse, xml.etree.ElementTree as ET
path, save_key = sys.argv[1:]
root = ET.parse(path).getroot()
node = root.find(f".//*[@name='{save_key}']")
if node is None:
    raise SystemExit(f"Missing save key: {save_key}")
# Use unquote, not unquote_plus, so literal '+' characters remain unchanged.
data = json.loads(urllib.parse.unquote(node.text or ""))
c = data.get("currency", {})
print("Snapshot:", path)
print("Techpoints:", c.get("techpoints"))
print("Credits:", c.get("credits"))
print("Techpoints collected:", c.get("techpointsCollected"))
print("Credits collected:", c.get("creditsCollected"))
PY
