# helpers.sh – Kurzbefehle für Tag 4. Laden mit: source ~/renovate-lab/tag04/helpers.sh
R="$FORGEJO/api/v1/repos/shop/shop-api"
# offene PRs: Nummer, Branch, Titel
prs() { curl -s -u "$ADMIN" "$R/pulls?state=open&limit=50" \
  | jq -r '.[] | "#\(.number) \(.head.ref)  \(.title)"'; }
# Pakete im PR eines Branches: pkgs all-minor-patch
pkgs() { curl -s -u "$ADMIN" "$R/pulls?state=open&limit=50" \
  | jq -r --arg b "renovate/$1" '.[] | select(.head.ref == $b) | .body' \
  | sed -nE 's/^\| \[([^]]+)\].*`([^`]+)` → `([^`]+)`.*/\1: \2 -> \3/p'; }
# Renovate-Status-Checks am Branch-Kopf: checks all-minor-patch
checks() { local sha
  sha=$(curl -s -u "$ADMIN" "$R/branches/renovate/$1" | jq -r .commit.id)
  curl -s -u "$ADMIN" "$R/commits/$sha/status" | jq -r '.statuses[]
    | select(.context | startswith("renovate/"))
    | "\(.context): \(.status) – \(.description)"'; }
# Text des Dependency Dashboards
dash() { curl -s -u "$ADMIN" "$R/issues?state=open&type=issues&limit=50" \
  | jq -r '.[] | select(.title == "Dependency Dashboard") | .body'; }
# renovate.json prüfen, alles committen und pushen: ship "Nachricht"
ship() { renovate-config-validator --no-global renovate.json >/dev/null \
  && git add -A && git commit -qm "$1" && git push -q origin main && echo "✔ $1"; }
