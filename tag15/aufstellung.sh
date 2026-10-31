#!/usr/bin/env bash
# aufstellung.sh – baut die Startzustände für den Wettkampf (Tag 15) in der Org shop.
# Mehrfach aufrufbar: Repos werden neu angelegt. Dauer ca. 3–5 min.
set -euo pipefail
LAB="${LAB:-$HOME/renovate-lab}"
source "$LAB/setup/env.sh"
CODE="$LAB/code/tag15"; W="$LAB/tag15"; FJ="${FORGEJO_NAME:-forgejo}"
mkdir -p "$W" && cd "$W"
api() { curl -sf -u "$ADMIN" -H 'Content-Type: application/json' "$@"; }

# 1. Org shop nur für angemeldete Benutzer (wie Tag 8), sonst ist die Registry offen
api -X PATCH "$FORGEJO/api/v1/orgs/shop" -d '{"visibility":"limited"}' >/dev/null \
  || "$LAB/setup/seed.sh" >/dev/null
api -X PATCH "$FORGEJO/api/v1/orgs/shop" -d '{"visibility":"limited"}' >/dev/null

# 2. Paket @shop/money 1.0.0 und 1.1.0 in der Forgejo-Registry (Runde 7)
docker exec "$FJ" forgejo admin user generate-access-token --username lab-admin \
  --token-name "wk-publish-$$" --scopes write:package --raw > pkg-token
tmp=$(mktemp -d)
{ echo "@shop:registry=$FORGEJO/api/packages/shop/npm/"
  echo "${FORGEJO#http:}/api/packages/shop/npm/:_authToken=$(cat pkg-token)"
} > "$tmp/npmrc"
for v in 1.0.0 1.1.0; do
  if ! api "$FORGEJO/api/packages/shop/npm/@shop%2fmoney" \
      | jq -e --arg v "$v" '.versions[$v]' >/dev/null 2>&1; then
    rm -rf "$tmp/money" && cp -R "$LAB/code/tag08/money" "$tmp/money"
    jq --arg v "$v" '.version = $v' "$LAB/code/tag08/money/package.json" \
      > "$tmp/money/package.json"
    npm publish "$tmp/money" --userconfig "$tmp/npmrc" >/dev/null 2>&1
  fi
done
api -X DELETE "$FORGEJO/api/v1/users/lab-admin/tokens/wk-publish-$$" >/dev/null
rm -rf "$tmp" pkg-token

# 3. Sieben Repos: Basis (shop-api oder leer) + Dateien aus repos/<name>
neu() {   # neu <repo> <basis|-> <actions true|false>
  local src; src=$(mktemp -d)
  [ "$2" = "-" ] || cp -R "$LAB/setup/$2/." "$src"
  cp -R "$CODE/repos/$1/." "$src"
  [ "$1" = bezahlung ] && printf '@shop:registry=%s/api/packages/shop/npm/\n' \
    "$FORGEJO" > "$src/.npmrc"
  "$LAB/setup/mkrepo.sh" "shop/$1" "$src" >/dev/null
  api -X PATCH "$FORGEJO/api/v1/repos/shop/$1" -d "{\"has_actions\":$3}" >/dev/null
  rm -rf "$src"; echo "✔ shop/$1 (Actions: $3)"
}
neu kasse shop-api false       # Runde 1: renovate.json mit Syntaxfehler
neu werkzeug - false           # Runde 3: Regex-Manager matcht nicht
neu automat shop-api true      # Runde 4: Forgejo Actions an, kein Runner
neu flut - false               # Runde 5: alle Limits aus, alles einzeln
neu major shop-api false       # Runde 6: Major-PR wird gleich geschlossen
neu bezahlung - false          # Runde 7: privates Paket ohne Zugangsdaten
neu lager - false              # Runde 8: Gruppe abgeschaltet, Lockfile scheitert

# 4. Runde 2: Ein Kollege hat den Bot-Token "rotiert" – mit zu wenig Scopes
curl -s -u renovate-bot:lab-bot-pw-123 -X DELETE \
  "$FORGEJO/api/v1/users/renovate-bot/tokens/renovate-rotation" >/dev/null || true
docker exec "$FJ" forgejo admin user generate-access-token --username renovate-bot \
  --token-name renovate-rotation --scopes read:repository --raw | tr -d '\n' > wk-token
chmod 600 wk-token

# 5. Nachtlauf über alle sieben Repos (mit dem alten, gültigen Token)
echo "… Nachtlauf (1–3 min)"
renovate shop/kasse shop/werkzeug shop/automat shop/flut shop/major shop/bezahlung \
  shop/lager > nacht.log 2>&1 || true

# 6. Runde 6: Jemand hat den express-Major-PR geschlossen, danach lief Renovate erneut
nr=$(api "$FORGEJO/api/v1/repos/shop/major/pulls?state=open&limit=50" \
  | jq -r '.[] | select(.head.ref == "renovate/express-5.x") | .number')
api -X PATCH "$FORGEJO/api/v1/repos/shop/major/pulls/$nr" -d '{"state":"closed"}' \
  >/dev/null
renovate shop/major > nacht2.log 2>&1 || true
grep -h '"result"' nacht.log nacht2.log | sort | uniq -c
echo "✔ Aufstellung fertig – weiter mit ./wk-check.sh"
