#!/data/data/com.termux/files/usr/bin/python
"""Read-only Angry Birds 2 save inspector for the tested 26.7.0 format.

Requirements: rooted Android, Termux, Python 3, pycryptodome.
No player-specific AES key/IV is embedded; both are read from save/index at runtime.
The script prints only wallet values and does not print account IDs, AES material, or full save JSON.
"""

from __future__ import annotations
import argparse, json, shlex, struct, subprocess
from Crypto.Cipher import AES
from Crypto.Util.Padding import unpad

PKG = "com.rovio.baba"
SAVE_FILENAME = "B4F59D3E9582F13D98B85102B4003E377A9434837B71846F44C05637D2613FA1"
DEFAULT_SAVE_DIR = f"/storage/emulated/0/Android/data/{PKG}/files/save"
HFS_MAGIC = bytes.fromhex("5d34ea46460e724d9da530b8f0bbad3b")
SALT = bytes.fromhex(
    "f4a2cdbe75c71520aefb9d6b6a267cdacd209036da3861411551d5d4e437add0"
    "2f3580c312a14899685a87f3bd2063e713bfa5f06cb863a5b02e19b654360b5a"
    "e616d996352e8d1458052e48f26744dad43d9ce57664bc4bfe205ca31cef73d3"
    "4157c4f2fb4c954c90eac1e16cb30f784275ae4ad6a788d9712899553d922325"
    "e365d57cd29effb75869e024901c31eb605641e398486879f8cf05ec2450faf3"
    "c5545830d910759a55227538de5e33caf46319d42470f33fb7890636f815b3d7"
    "61c0e54258f2d0b6f8647b8416e9a142154caaba2b9510988f11e22e355b5d92"
    "4e4539fd25f899988d5567b7eeb2e237f6133967aa027a8e7611ffd7c87ffe7a"
)

def root_read(path: str) -> bytes:
    p = subprocess.run(["su", "-c", f"cat {shlex.quote(path)}"], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    return p.stdout

def strip_header(raw: bytes, label: str) -> bytes:
    if raw.startswith(HFS_MAGIC):
        if len(raw) < 36 or struct.unpack_from("<i", raw, 16)[0] != 1:
            raise SystemExit(f"Invalid {label} HashedFileSystem header")
        return raw[36:]
    return raw

def decode_index(raw: bytes):
    payload = bytearray(strip_header(raw, "index"))
    if len(payload) < 8 or payload[:2] != b"\xab\xba" or struct.unpack_from("<h", payload, 2)[0] != 1:
        raise SystemExit("Unexpected save/index format")
    for i in range(4, len(payload)):
        payload[i] ^= SALT[(i - 4) % len(SALT)]
    a, b = struct.unpack_from("<hh", payload, 4)
    candidates = []
    if a == 16 and b in (16, 24, 32) and 8 + a + b == len(payload):
        candidates.append((bytes(payload[8+a:]), bytes(payload[8:8+a])))
    if b == 16 and a in (16, 24, 32) and 8 + a + b == len(payload):
        candidates.append((bytes(payload[8:8+a]), bytes(payload[8+a:])))
    if len(candidates) != 1:
        raise SystemExit(f"Could not decode AES parameter layout ({a}, {b})")
    return candidates[0]

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--save-dir", default=DEFAULT_SAVE_DIR)
    args = ap.parse_args()
    d = args.save_dir.rstrip("/")
    index_raw = root_read(f"{d}/index")
    main_raw = strip_header(root_read(f"{d}/{SAVE_FILENAME}"), "main save")
    key, iv = decode_index(index_raw)
    plaintext = unpad(AES.new(key, AES.MODE_CBC, iv).decrypt(main_raw), AES.block_size).decode("utf-16le")
    outer = json.loads(plaintext)
    wallet = json.loads(outer["PD_Wallet"])
    print("Gems:", wallet.get("Gems"))
    print("PaidGems:", wallet.get("PaidGems"))
    print("SecondaryCurrency:", wallet.get("SecondaryCurrency"))
    print("FreeBirdTokens:", wallet.get("FreeBirdTokens"))
    print("TOFExpressTickets:", wallet.get("TOFExpressTickets"))
    print("TOFEntryTickets:", wallet.get("TOFEntryTickets"))
    print("ArenaTickets:", wallet.get("ArenaTickets"))
    print("Player/account identifiers and AES key/IV intentionally omitted from output.")

if __name__ == "__main__":
    main()
