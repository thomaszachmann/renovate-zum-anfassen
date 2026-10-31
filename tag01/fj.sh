# fj.sh – Helfer für die Forgejo-API an Tag 1. Laden mit: source fj.sh
API="$FORGEJO/api/v1/repos/shop/shop-api"
api() { curl -sf -u "$ADMIN" -H 'Content-Type: application/json' "$@"; }
prs() {     # PRs auflisten: prs [open|closed|all]
  api "$API/pulls?state=${1:-open}&limit=50" | jq -r 'sort_by(.number)[]
    | "#\(.number) \(if .merged then "merged" else .state end)"
      + " \(.head.label) | \(.title)"'
}
issues() {  # offene Issues (ohne PRs) auflisten
  api "$API/issues?type=issues&state=open" | jq -r '.[] | "#\(.number) \(.title)"'
}
body() { api "$API/issues/$1" | jq -r .body; }   # Text von Issue/PR <nr>
tick() {    # Checkbox abhaken: tick <issue-nr> <marker aus dem HTML-Kommentar>
  body "$1" | sed "s|- \[ \] <!-- $2 -->|- [x] <!-- $2 -->|" \
    | jq -Rs '{body: .}' | api -X PATCH "$API/issues/$1" -d @- >/dev/null
}
