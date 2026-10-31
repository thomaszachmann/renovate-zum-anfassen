# kontrolle.sh – Kontrollpunkt Tag 9. Aufruf im Ordner ~/renovate-lab/tag09:
#   source ~/renovate-lab/setup/env.sh && source helpers.sh && bash kontrolle.sh
unset RENOVATE_PLATFORM RENOVATE_ENDPOINT RENOVATE_GIT_AUTHOR RENOVATE_CONFIG_FILE
source ./helpers.sh
ok() { if eval "$2" >/dev/null 2>&1; then echo "✔ $1"; else echo "✘ $1"; fi; }
ok "config.js ist gültige globale Config" "renovate-config-validator config.js"
ok "kein Token im Klartext in config.js" \
  "grep -q 'process.env.RENOVATE_TOKEN' config.js && ! grep -qE \"token: '\" config.js"
renovate --write-discovered-repos=k.json >/dev/null 2>&1
ok "autodiscover findet shop, aber nicht lager" \
  "jq -e 'any(startswith(\"shop/\")) and all(startswith(\"lager/\") | not)' k.json"
ok "Onboarding-PR in shop-api geschlossen" \
  "prs shop/shop-api closed | grep -q 'renovate/onboarding'"
ok "shop-deploy wieder aktiv (kein enabled: false)" \
  "! raw shop/shop-deploy main renovate.json | grep -q '\"enabled\": false'"
ok "Repository-Cache liegt im baseDir" \
  "ls work/cache/renovate/repository/forgejo/shop/*.json"
ok "JSON-Log enthält Laufzusammenfassung" "summary cache1.json | grep -q ms"
