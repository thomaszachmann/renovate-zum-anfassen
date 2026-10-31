#!/usr/bin/env bash
# kontrolle.sh – Kontrollpunkt Tag 1 (✔/✘)
source ~/renovate-lab/setup/env.sh
API="$FORGEJO/api/v1/repos/shop/shop-api"
api() { curl -sf -u "$ADMIN" "$@"; }
t() { if eval "$2" >/dev/null 2>&1; then echo "✔ $1"; else echo "✘ $1"; fi; }
t "renovate.json auf main mit config:recommended" \
  "api $API/raw/renovate.json | jq -e '.extends | index(\"config:recommended\")'"
t "Onboarding-PR #1 gemergt" "api $API/pulls/1 | jq -e .merged"
t "Dependency Dashboard offen" \
  "api '$API/issues?type=issues&state=open' \
     | jq -e 'any(.[]; .title == \"Dependency Dashboard\")'"
t "express auf main = 4.22.x" \
  "api $API/raw/package.json | jq -e '.dependencies.express | startswith(\"4.22.\")'"
t "Branch renovate/express-4.x aufgeräumt" \
  "! api $API/branches/renovate%2Fexpress-4.x"
t "PR #8 geschlossen, Ignore-Kommentar vorhanden" \
  "api $API/issues/8/comments | jq -e 'any(.[]; .body | test(\"Ignore Notification\"))'"
