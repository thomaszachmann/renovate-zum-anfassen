#!/usr/bin/env bash
# kontrolle.sh – Kontrollpunkt Tag 10
source ~/renovate-lab/setup/env.sh
K="kubectl --context kind-renovate-lab -n renovate"
t() { if eval "$2" >/dev/null 2>&1; then echo "✔ $1"; else echo "✘ $1"; fi; }
t "Forgejo hängt im Docker-Netz kind" \
  "docker inspect forgejo -f '{{json .NetworkSettings.Networks}}' | grep -q '\"kind\"'"
t "CronJob renovate mit concurrencyPolicy Forbid" \
  "[ \"\$($K get cronjob renovate -o jsonpath='{.spec.concurrencyPolicy}')\" = Forbid ]"
t "Token im Secret, nicht in der ConfigMap" \
  "$K get secret renovate-env && ! $K get cm renovate-config -o yaml \
     | grep -qF \"\$RENOVATE_TOKEN\""
t "Job renovate-manual erfolgreich" \
  "[ \"\$($K get job renovate-manual -o jsonpath='{.status.succeeded}')\" = 1 ]"
t "PVC renovate-cache gebunden" \
  "[ \"\$($K get pvc renovate-cache -o jsonpath='{.status.phase}')\" = Bound ]"
t "Onboarding-PR von renovate-bot in shop/shop-api" \
  "curl -sf -u \$ADMIN '$FORGEJO/api/v1/repos/shop/shop-api/pulls?state=all' \
     | jq -e 'any(.[]; .user.login == \"renovate-bot\")'"
