#!/usr/bin/env bash
# sabotage.sh – stört shop/shop-api für die Challenge von Tag 14
source ~/renovate-lab/setup/env.sh
cd "$(dirname "$0")" && source fj.sh
nr() { api "$API/pulls?state=open&limit=50" \
  | jq -r --arg b "$1" '.[] | select(.head.ref == $b) | .number'; }
api -X PATCH "$API/pulls/$(nr renovate/express-5.x)" -d '{"state":"closed"}' >/dev/null
tmp=$(mktemp -d)
git clone -q -b renovate/node-20.x \
  "http://$ADMIN@127.0.0.1:3000/shop/shop-api.git" "$tmp"
echo "# Hotfix" >> "$tmp/Dockerfile"
git -C "$tmp" -c user.name="Kollege" -c user.email=k@lab.local \
  commit -qam "Hotfix im Renovate-Branch"
git -C "$tmp" push -q origin renovate/node-20.x 2>/dev/null
rm -rf "$tmp"
echo "✔ Sabotage erledigt"
