#!/usr/bin/env bash
# check.sh – prüft das Trainingsgelände (✔/✘). Exit-Code = Anzahl Fehler.
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/env.sh"
fail=0
ok()  { echo "✔ $1"; }
bad() { echo "✘ $1"; fail=$((fail + 1)); }
t()   { if eval "$2" >/dev/null 2>&1; then ok "$1"; else bad "$1"; fi; }

t "Docker läuft" "docker info"
t "Node 24 (node -v)" "node -v | grep -q '^v24\.'"
t "Renovate-CLI im PATH" "renovate --version"
t "Forgejo erreichbar unter $FORGEJO" "curl -sf $FORGEJO/api/healthz"
t "Bot-Token gültig (renovate-bot)" \
  "curl -sf -H \"Authorization: token \$RENOVATE_TOKEN\" $FORGEJO/api/v1/user \
     | jq -e '.login == \"renovate-bot\"'"
t "Repo shop/shop-api vorhanden (sonst: seed.sh)" \
  "curl -sf -u \$ADMIN $FORGEJO/api/v1/repos/shop/shop-api"
t "Bot darf in shop/shop-api schreiben" \
  "curl -sf -H \"Authorization: token \$RENOVATE_TOKEN\" \
     $FORGEJO/api/v1/repos/shop/shop-api | jq -e '.permissions.push'"
exit "$fail"
