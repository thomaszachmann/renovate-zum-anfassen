#!/usr/bin/env bash
# neu.sh <config.json> – shop-api frisch anlegen, Forgejo Actions aus,
# die Datei als renovate.json auf main pushen.
set -euo pipefail
LAB="${LAB:-$HOME/renovate-lab}"
source "$LAB/setup/env.sh"
CFG="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
"$LAB/setup/seed.sh" --reset >/dev/null
curl -sf -u "$ADMIN" -H 'Content-Type: application/json' -X PATCH \
  "$FORGEJO/api/v1/repos/shop/shop-api" -d '{"has_actions":false}' >/dev/null
cd "$LAB/tag05" && rm -rf shop-api
git clone -q "http://$ADMIN@127.0.0.1:$FORGEJO_PORT/shop/shop-api.git"
cd shop-api
git config user.name "Lab Admin" && git config user.email admin@lab.local
cp "$CFG" renovate.json
renovate-config-validator >/dev/null && echo "✔ $(basename "$CFG") ist gültig"
git add renovate.json && git commit -qm "Renovate-Konfiguration" && git push -q
echo "✔ shop-api neu, Actions aus, renovate.json auf main"
