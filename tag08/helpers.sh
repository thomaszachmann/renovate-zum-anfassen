# helpers.sh – Kurzbefehle für Tag 8. Laden mit: source ~/renovate-lab/tag08/helpers.sh
R="$FORGEJO/api/v1/repos/shop/shop-api"
# offene PRs: Nummer, Branch, Titel (auf 88 Zeichen gekürzt)
prs() { curl -s -u "$ADMIN" "$R/pulls?state=open&limit=50" \
  | jq -r '.[] | "#\(.number) \(.head.ref)  \(.title)"' | cut -c1-88; }
# Text des Dependency Dashboards
dash() { curl -s -u "$ADMIN" "$R/issues?state=open&type=issues&limit=50" \
  | jq -r '.[] | select(.title == "Dependency Dashboard") | .body'; }
# renovate.json prüfen, alles committen und pushen: ship "Nachricht"
ship() { renovate-config-validator --no-global renovate.json >/dev/null \
  && git add -A && git commit -qm "$1" && git push -q origin main && echo "✔ $1"; }
