#!/usr/bin/env bash
# status.sh [org/repo] – listet offene PRs und Issues (Standard: shop/shop-api)
set -euo pipefail
source "${LAB:-$HOME/renovate-lab}/setup/env.sh"
REPO="${1:-shop/shop-api}"
for kind in pulls issues; do
  json=$(curl -sf -u "$ADMIN" \
    "$FORGEJO/api/v1/repos/$REPO/issues?state=open&type=$kind")
  echo "== $kind: $(jq length <<<"$json") offen"
  jq -r '.[] | "#\(.number)  \(.title)  (\(.user.login))"' <<<"$json"
done
