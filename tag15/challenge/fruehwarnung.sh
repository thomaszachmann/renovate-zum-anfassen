#!/usr/bin/env bash
# fruehwarnung.sh – Warnsignale aus dem Wettkampf für alle Repos der Org shop.
# Nutzung: ./fruehwarnung.sh [max-offene-PRs]   (Default 10, wie prConcurrentLimit)
LAB="${LAB:-$HOME/renovate-lab}"
source "$LAB/setup/env.sh"
MAX="${1:-10}"; found=0
api() { curl -sf -u "$ADMIN" "$@"; }
warn() { printf '%-10s %s\n' "$1" "$2"; found=$((found + 1)); }
for r in $(api "$FORGEJO/api/v1/orgs/shop/repos?limit=50" | jq -r '.[].name' | sort); do
  A="$FORGEJO/api/v1/repos/shop/$r"
  iss=$(api "$A/issues?type=issues&state=open&limit=50")
  jq -e '.[] | select(.title | startswith("Action Required"))' <<<"$iss" >/dev/null \
    && warn "$r" "Config-Fehler-Issue offen"
  jq -r '.[] | select(.title == "Dependency Dashboard") | .body' <<<"$iss" \
    | grep -q 'Failed to look up' && warn "$r" "Lookup-Fehler im Dashboard"
  prs=$(api "$A/pulls?state=open&limit=50")
  n=$(jq length <<<"$prs"); [ "$n" -gt "$MAX" ] && warn "$r" "PR-Flut: $n offen"
  for b in $(jq -r '.[] | select(.user.login == "renovate-bot") | .head.ref' <<<"$prs")
  do
    st=$(api "$A/commits/${b//\//%2F}/status")
    jq -e '.statuses[]? | select(.context == "renovate/artifacts"
      and .status == "failure")' <<<"$st" >/dev/null \
      && warn "$r" "Artefakt-Fehler: $b"
    jq -e --arg b "$b" '.[] | select(.head.ref == $b)
      | .body | contains("**Automerge**: Enabled")' <<<"$prs" >/dev/null \
      && [ "$(jq -r .state <<<"$st")" = pending ] \
      && warn "$r" "Automerge wartet auf pending: $b"
  done
done
echo "Warnsignale: $found"
