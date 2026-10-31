#!/usr/bin/env bash
# kontrolle.sh – Kontrollpunkt Tag 14 (✔/✘)
source ~/renovate-lab/setup/env.sh
API="$FORGEJO/api/v1/repos/shop/shop-api"
api() { curl -sf -u "$ADMIN" "$@"; }
t() { if eval "$2" >/dev/null 2>&1; then echo "✔ $1"; else echo "✘ $1"; fi; }
open_issues() { api "$API/issues?type=issues&state=open&limit=50"; }
t "Dashboard heißt Renovate-Steuerpult und trägt Label renovate" \
  "open_issues | jq -e 'any(.[]; .title == \"Renovate-Steuerpult\"
     and any(.labels[]; .name == \"renovate\"))'"
t "kein verwaistes Dependency Dashboard offen" \
  "open_issues | jq -e 'all(.[]; .title != \"Dependency Dashboard\")'"
t "kein Issue „Action Required“ offen" \
  "open_issues | jq -e 'all(.[]; .title | startswith(\"Action Required\") | not)'"
t "Majors brauchen Freigabe (packageRule)" \
  "api $API/raw/renovate.json | jq -e 'any(.packageRules[];
     .dependencyDashboardApproval == true and .matchUpdateTypes == [\"major\"])'"
t "Tippfehler aus package.json entfernt" \
  "api $API/raw/package.json | jq -e '.dependencies | has(\"expres-validator\") | not'"
t "Bot hat Schreibrecht" \
  "curl -sf -H \"Authorization: token \$RENOVATE_TOKEN\" $API | jq -e .permissions.push"
t "kein Renovate-Branch mit Status failure" \
  "! api '$API/pulls?state=open&limit=50' | jq -r '.[].head.sha' | while read s; do
     api $API/commits/\$s/status | jq -r .state; done | grep -q failure"
