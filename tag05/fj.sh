# fj.sh – Helfer für die Forgejo-API an Tag 5. Laden mit: source fj.sh
API="$FORGEJO/api/v1/repos/shop/shop-api"
api() { curl -sf -u "$ADMIN" -H 'Content-Type: application/json' "$@"; }
prs() {     # PRs auflisten: prs [open|closed|all]
  api "$API/pulls?state=${1:-open}&limit=50" | jq -r 'sort_by(.number)[]
    | "#\(.number) \(if .merged then "merged" else .state end)"
      + " \(.head.label) | \(.title)"'
}
sha() { api "$API/branches/${1//\//%2F}" | jq -r .commit.id; }   # sha <branch>
ci() {      # Commit-Status setzen: ci <branch> <pending|success|failure> [context]
  api -X POST "$API/statuses/$(sha "$1")" \
    -d "{\"state\":\"$2\",\"context\":\"${3:-ci/test}\",\"description\":\"Lab-CI\"}" \
    | jq -r '"\(.context) = \(.status)"'
}
checks() {  # Status-Checks eines Branches: checks <branch>
  api "$API/commits/${1//\//%2F}/status" | jq -r '"gesamt: \(.state)",
    ((.statuses // [])[] | "  \(.context) = \(.status)")'
}
mainlog() { # letzte Commits auf main: mainlog [anzahl]
  api "$API/commits?sha=main&limit=${1:-3}" \
    | jq -r '.[] | "\(.sha[0:7]) \(.commit.message | split("\n")[0] | .[0:72])"'
}
lauf() {    # Renovate-Lauf mit Debug-Log, Zeilen filtern: lauf <branch-teil> <regex>
  LOG_LEVEL=debug renovate shop/shop-api > lauf.log 2>&1
  grep -E "branch=renovate/$1" lauf.log | grep -E "$2" | sed -E \
    's/^ ?(.*) \(repository=shop\/shop-api, branch=renovate\/([^)]*)\)$/[\2] \1/' \
    | cut -c1-88
}
