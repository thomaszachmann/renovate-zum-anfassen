#!/usr/bin/env bash
# kontrolle.sh – Kontrollpunkt Tag 12. Aufruf im Klon ~/renovate-lab/tag12/shop-api
source "$(dirname "$0")/helpers.sh"
ok() { echo "✔ $1"; }; nok() { echo "✘ $1"; }
jq -e '.osvVulnerabilityAlerts == true' renovate.json >/dev/null \
  && ok "osvVulnerabilityAlerts an" || nok "osvVulnerabilityAlerts fehlt"
jq -e '.extends | index("config:best-practices")' renovate.json >/dev/null \
  && ok "config:best-practices aktiv" || nok "config:best-practices fehlt"
[ "$(prs | grep -c '\[SECURITY\] \[security\]')" -ge 2 ] \
  && ok "Security-PRs mit Label offen" || nok "Security-PRs fehlen"
grep -qE 'actions/checkout@[0-9a-f]{40} # v' .github/workflows/ci.yml \
  && ok "actions/checkout per SHA gepinnt" || nok "actions/checkout nicht gepinnt"
diffb prettier-3.x | grep -q '^+const preise = { apfel' \
  && ok "postUpgradeTask hat formatiert" || nok "preise.js unformatiert"
api "$R/branch_protections/main" | jq -e '.enable_push == false
  and (.push_whitelist_usernames | index("renovate-bot") | not)' >/dev/null \
  && ok "main geschützt, Bot ohne Ausnahme" || nok "Branch-Schutz fehlt"
