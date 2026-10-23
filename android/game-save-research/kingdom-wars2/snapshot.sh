#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# Kingdom Wars2 6.1.8 snapshot helper.
# This is intentionally read-only: the outer gameboost codec was not fully verified in our session.
# Requirements: rooted Android + Termux + Python 3.
# Usage: ./snapshot.sh

PKG='com.spcomes.kw2'
TARGET="/data/user/0/$PKG/shared_prefs/Cocos2dxPrefsFile.xml"
SAVE_KEY='com.spcomes.kw2.userdefault.gamedata.main'
OUTDIR="$HOME/game-save-backups/kingdom-wars2"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="$OUTDIR/playerprefs-$STAMP.xml"
mkdir -p "$OUTDIR"

su -c 'id' >/dev/null
su -c "cat '$TARGET'" > "$OUT"

python - "$OUT" "$SAVE_KEY" <<'PY'
import sys, xml.etree.ElementTree as ET
path, key = sys.argv[1:]
root = ET.parse(path).getroot()
node = root.find(f".//*[@name='{key}']")
if node is None:
    raise SystemExit(f"Missing save key: {key}")
blob = node.text or ""
print("Snapshot:", path)
print("Encoded main-save characters:", len(blob))
print("Status: copied only; no modification was performed")
PY
