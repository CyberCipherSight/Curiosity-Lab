#!/data/data/com.termux/files/usr/bin/bash
set -u

fail=0

ok()   { printf '[OK]   %s\n' "$1"; }
warn() { printf '[WARN] %s\n' "$1"; }
err()  { printf '[FAIL] %s\n' "$1"; fail=1; }

if [ -n "${PREFIX:-}" ] && [ "${PREFIX}" = "/data/data/com.termux/files/usr" ]; then
  ok "Termux environment detected"
else
  warn "This was written for Termux on Android"
fi

if command -v su >/dev/null 2>&1; then
  if su -c id 2>/dev/null | grep -q 'uid=0'; then
    ok "Root access works through su"
  else
    err "su exists, but root access was not granted"
  fi
else
  err "su is missing; Magisk/root access is required for private app data"
fi

if command -v python >/dev/null 2>&1; then
  ok "Python 3 is available"
else
  err "Python is missing (Termux: pkg install python)"
fi

if command -v python >/dev/null 2>&1; then
  if python - <<'PY' >/dev/null 2>&1
from Crypto.Cipher import AES
from Crypto.Util.Padding import pad, unpad
PY
  then
    ok "PyCryptodome is available"
  else
    err "PyCryptodome is missing (Termux: pip install pycryptodome)"
  fi
fi

if command -v pidof >/dev/null 2>&1 || su -c 'command -v pidof' >/dev/null 2>&1; then
  ok "pidof is available"
else
  warn "pidof was not found; game process shutdown may need adjustment"
fi

printf '\nRequirements used by these scripts:\n'
printf '  - rooted Android device with working su/Magisk\n'
printf '  - Termux\n'
printf '  - Python 3\n'
printf '  - PyCryptodome\n'
printf '  - the target game installed and initialized at least once\n'
printf '  - enough free storage for an automatic backup\n'
printf '\nNo device serial, account ID, installation ID, or player-specific encryption key is embedded in this repository.\n'

exit "$fail"
