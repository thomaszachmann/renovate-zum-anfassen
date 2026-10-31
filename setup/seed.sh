#!/usr/bin/env bash
# seed.sh – legt Organisation "shop" und das Demo-Repo shop/shop-api an.
# --reset löscht shop-api vorher (frischer Stand wie an Tag 0).
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/env.sh"
api() { curl -sf -u "$ADMIN" -H 'Content-Type: application/json' "$@"; }
api "$FORGEJO/api/v1/orgs/shop" >/dev/null \
  || api -X POST "$FORGEJO/api/v1/orgs" -d '{"username":"shop"}' >/dev/null
if [ "${1:-}" = "--reset" ]; then
  api -X DELETE "$FORGEJO/api/v1/repos/shop/shop-api" >/dev/null || true
fi
if ! api "$FORGEJO/api/v1/repos/shop/shop-api" >/dev/null; then
  api -X POST "$FORGEJO/api/v1/orgs/shop/repos" \
    -d '{"name":"shop-api","default_branch":"main"}' >/dev/null
  tmp=$(mktemp -d)
  cp -R "$DIR/shop-api/." "$tmp"
  git -C "$tmp" init -q -b main
  git -C "$tmp" add -A
  git -C "$tmp" -c user.name="Lab Admin" -c user.email=admin@lab.local \
    commit -qm "Initialer Stand"
  git -C "$tmp" push -q "http://$ADMIN@127.0.0.1:$FORGEJO_PORT/shop/shop-api.git" main
  rm -rf "$tmp"
fi
api -X PUT "$FORGEJO/api/v1/repos/shop/shop-api/collaborators/renovate-bot" \
  -d '{"permission":"write"}' >/dev/null
# Forgejo meldet ein frisch gepushtes Repo kurz als leer – warten
until api "$FORGEJO/api/v1/repos/shop/shop-api" | jq -e '.empty == false' >/dev/null; do
  sleep 1
done
echo "✔ Org shop, Repo shop/shop-api, Bot renovate-bot als Collaborator"
