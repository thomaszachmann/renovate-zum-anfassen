#!/usr/bin/env bash
# kontrolle.sh – Kontrollpunkt Tag 11 (✔/✘)
source "${LAB:-$HOME/renovate-lab}/setup/env.sh"
source "$(dirname "$0")/helpers.sh"
t() { if eval "$2" >/dev/null 2>&1; then echo "✔ $1"; else echo "✘ $1"; fi; }
R="$API/repos/shop/renovate-config"
t "Preset-Repo hat Tags v1.0.0 und v1.1.0" \
  "api $R/tags | jq -e '[.[].name] | index(\"v1.0.0\") and index(\"v1.1.0\")'"
t "Bot darf Presets lesen, aber nicht schreiben" \
  "curl -sf -H \"Authorization: token \$RENOVATE_TOKEN\" $R \
     | jq -e '.permissions.pull and (.permissions.push | not)'"
t "shop-deploy nutzt versionierte Presets (#v…)" \
  "api $API/repos/shop/shop-deploy/raw/renovate.json | grep -q 'renovate-config#v'"
t "shop-api: PR mit Team-Label aus Parameter" \
  "prs shop/shop-api | grep -q team-shop"
t "shop-worker: kein offenes Config-Fehler-Issue" \
  "! issues shop/shop-worker | grep -q 'Action Required'"
t "shop-notify: PRs ohne eigene renovate.json (inheritConfig)" \
  "prs shop/shop-notify | grep -q 'non-major'"
