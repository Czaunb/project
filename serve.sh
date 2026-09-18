#!/usr/bin/env bash
# Kiszolgálja a Quest demót a gépedről egy ideiglenes HTTPS-címen (cloudflared).
# Használat:
#   ./serve.sh                       # quest-mr-demo.html vagy index.html a mappában
#   ./serve.sh /ut/quest-mr-demo.html
#   ./serve.sh --lt                  # localtunnel a cloudflared helyett
#   PORT=9000 ./serve.sh             # más helyi port

set -euo pipefail

PORT="${PORT:-8080}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USE_LT=0
SRC=""

for arg in "$@"; do
  case "$arg" in
    --lt) USE_LT=1 ;;
    -h|--help) sed -n '2,8p' "$0"; exit 0 ;;
    *) SRC="$arg" ;;
  esac
done

# --- a kiszolgálandó fájl ---
if [ -z "$SRC" ]; then
  for cand in "quest-mr-demo.html" "index.html" "$HERE/quest-mr-demo.html" "$HERE/index.html"; do
    [ -f "$cand" ] && { SRC="$cand"; break; }
  done
fi
if [ -z "$SRC" ] || [ ! -f "$SRC" ]; then
  echo "HIBA: nem találom a HTML fájlt." >&2
  echo "Add meg útvonallal:  $0 /eleresi/ut/quest-mr-demo.html" >&2
  exit 1
fi

PY="$(command -v python3 || command -v python || true)"
if [ -z "$PY" ]; then
  echo "HIBA: nincs python. Telepítsd, vagy használd helyette: npx serve -l $PORT" >&2
  exit 1
fi

# --- tiszta kiszolgáló mappa: a demó index.html néven, hogy a cím rövid legyen ---
WWW="$(mktemp -d)"
cp "$SRC" "$WWW/index.html"
[ -f "$HERE/check.html" ] && cp "$HERE/check.html" "$WWW/check.html"
chmod 644 "$WWW"/*.html

HTTP_PID=""
TUN_PID=""
CLEANED=0
cleanup() {
  [ "$CLEANED" = "1" ] && return 0
  CLEANED=1
  [ -n "$HTTP_PID" ] && kill "$HTTP_PID" 2>/dev/null || true
  [ -n "$TUN_PID" ]  && kill "$TUN_PID"  2>/dev/null || true
  rm -rf "$WWW"
  echo ""
  echo "Leállítva."
}
trap cleanup EXIT INT TERM

echo "Kiszolgálás: $SRC"
"$PY" -m http.server "$PORT" --bind 127.0.0.1 --directory "$WWW" >/dev/null 2>&1 &
HTTP_PID=$!
sleep 1
if ! kill -0 "$HTTP_PID" 2>/dev/null; then
  echo "HIBA: a helyi szerver nem indult el (foglalt a $PORT port?). Próbáld: PORT=9000 $0" >&2
  exit 1
fi
echo "Helyi szerver fut:  http://127.0.0.1:$PORT  (csak a gépedről érhető el)"

LOG="$WWW/tunnel.log"

# --- localtunnel ág ---
if [ "$USE_LT" = "1" ]; then
  command -v npx >/dev/null || { echo "HIBA: nincs npx (Node.js kell hozzá)." >&2; exit 1; }
  echo "Tunnel indítása (localtunnel)…"
  npx --yes localtunnel --port "$PORT" > "$LOG" 2>&1 &
  TUN_PID=$!
  for _ in $(seq 1 40); do
    URL="$(grep -o 'https://[a-z0-9-]*\.loca\.lt' "$LOG" 2>/dev/null | head -1 || true)"
    [ -n "${URL:-}" ] && break
    sleep 1
  done
  if [ -z "${URL:-}" ]; then echo "HIBA: nem kaptam localtunnel URL-t." >&2; cat "$LOG" >&2; exit 1; fi
  echo ""
  echo "  HTTPS-cím a headsethez:  $URL"
  echo ""
  echo "  FIGYELEM: a loca.lt első megnyitáskor jelszót kér."
  echo "  A jelszó a publikus IP-d, ezt írd be:"
  curl -s https://loca.lt/mytunnelpassword 2>/dev/null | sed 's/^/     /' || echo "     (lekérés: https://loca.lt/mytunnelpassword)"
  echo ""
  wait "$TUN_PID"
  exit 0
fi

# --- cloudflared ág (alapértelmezett) ---
if ! command -v cloudflared >/dev/null; then
  cat >&2 <<'MSG'

HIBA: a cloudflared nincs telepítve. Telepítsd az egyiket:

  macOS:    brew install cloudflared
  Windows:  winget install --id Cloudflare.cloudflared
  Linux:    curl -L -o /tmp/cf https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 \
              && sudo install /tmp/cf /usr/local/bin/cloudflared

Vagy futtasd telepítés nélkül, localtunnellel:   ./serve.sh --lt
MSG
  exit 1
fi

echo "Tunnel indítása (cloudflared)…"
cloudflared tunnel --url "http://127.0.0.1:$PORT" --no-autoupdate > "$LOG" 2>&1 &
TUN_PID=$!

URL=""
for _ in $(seq 1 45); do
  URL="$(grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' "$LOG" 2>/dev/null | head -1 || true)"
  [ -n "$URL" ] && break
  kill -0 "$TUN_PID" 2>/dev/null || break
  sleep 1
done

if [ -z "$URL" ]; then
  echo "HIBA: nem kaptam trycloudflare URL-t. A tunnel logja:" >&2
  tail -25 "$LOG" >&2
  exit 1
fi

echo ""
echo "============================================================"
echo "  Írd be a Quest böngészőjének címsorába:"
echo ""
echo "      $URL"
echo ""
echo "  Diagnosztika ugyanezen a címen:  $URL/check.html"
echo "============================================================"
echo ""
echo "A szkript futása alatt él a cím. Leállítás: Ctrl+C"
echo ""
wait "$TUN_PID"
