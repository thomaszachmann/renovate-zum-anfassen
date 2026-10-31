# kontrolle.sh – Kontrollpunkt Tag 6. Aufruf: bash ~/renovate-lab/code/tag06/kontrolle.sh
source ~/renovate-lab/setup/env.sh
cd ~/renovate-lab/tag06/shop-api && git pull -q
source ~/renovate-lab/code/tag06/helpers.sh
ok() { if eval "$2" >/dev/null 2>&1; then echo "✔ $1"; else echo "✘ $1"; fi; }
ok "renovate.json gültig" "renovate-config-validator --no-global renovate.json"
ok "lodash exakt gepinnt" "grep -q '\"lodash\": \"[0-9]' package.json"
ok "express exakt 4.18.2" "grep -q '\"express\": \"4.18.2\"' package.json"
ok "Dockerfile: Tag + Digest" "grep -qE '^FROM node:[0-9.]+-alpine@sha256:' Dockerfile"
ok "Digest-PR offen" "prs | grep -q 'renovate/node-20.11.0-alpine'"
ok "kein express-5-PR" "! prs | grep -q 'express-5'"
