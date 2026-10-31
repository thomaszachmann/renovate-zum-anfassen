#!/usr/bin/env bash
# kontrolle.sh – Kontrollpunkt Tag 5 (✔/✘)
source "${LAB:-$HOME/renovate-lab}/setup/env.sh"
API="$FORGEJO/api/v1/repos/shop/shop-api"
api() { curl -sf -u "$ADMIN" "$@"; }
t() { if eval "$2" >/dev/null 2>&1; then echo "✔ $1"; else echo "✘ $1"; fi; }
t "Forgejo Actions im Repo aus" "api $API | jq -e '.has_actions == false'"
t "Automerge-Regel für devDependencies" \
  "api $API/raw/renovate.json | jq -e '.packageRules[0].automerge == true'"
t "platformAutomerge aus (Renovate merged selbst)" \
  "api $API/raw/renovate.json | jq -e '.platformAutomerge == false'"
t "Branch-Protection main verlangt ci/test" \
  "api $API/branch_protections/main | jq -e '.status_check_contexts == [\"ci/test\"]'"
t "prettier-PR von Renovate gemergt" \
  "api '$API/pulls?state=closed' | jq -e 'any(.[]; .merged
     and .head.label == \"renovate/prettier-3.x\")'"
t "prettier auf main ist 3.x > 3.0.0" \
  "api $API/raw/package.json | jq -e '.devDependencies.prettier != \"3.0.0\"'"
