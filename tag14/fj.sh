# fj.sh – Helfer für Tag 14. Laden mit: source fj.sh
API="$FORGEJO/api/v1/repos/shop/shop-api"
api() { curl -sf -u "$ADMIN" -H 'Content-Type: application/json' "$@"; }
prs() {     # PRs auflisten: prs [open|closed|all]
  api "$API/pulls?state=${1:-open}&limit=50" | jq -r 'sort_by(.number)[]
    | "#\(.number) \(if .merged then "merged" else .state end)"
      + " \(.head.ref) | \(.title)"'
}
issues() {  # offene Issues (ohne PRs): issues
  api "$API/issues?type=issues&state=open&limit=50" \
    | jq -r '.[] | "#\(.number) \(.title) [\([.labels[].name] | join(","))]"'
}
body() { api "$API/issues/$1" | jq -r .body; }    # Text von Issue/PR <nr>
dashnr() {  # Nummer des Dashboards: dashnr [titel]
  api "$API/issues?type=issues&state=open&limit=50" | jq -r --arg t \
    "${1:-Dependency Dashboard}" '.[] | select(.title == $t) | .number'
}
tick() {    # Checkbox abhaken: tick <issue-/pr-nr> <marker im HTML-Kommentar>
  body "$1" | sed "s|- \[ \] <!-- $2 -->|- [x] <!-- $2 -->|" \
    | jq -Rs '{body: .}' | api -X PATCH "$API/issues/$1" -d @- \
    | jq -r --arg m "$2" '.body | if contains("[x] <!-- \($m) -->")
        then "✔ angehakt: \($m)" else "✘ nicht gefunden: \($m)" end'
}
boxes() {   # Checkboxen eines Issues/PRs: boxes <nr>
  body "$1" | grep -oE '\[[ x]\] <!-- [^ ]+ -->' | sed 's/<!-- //; s/ -->//'
}
sha() { api "$API/branches/${1//\//%2F}" | jq -r '.commit.id[0:7]'; }
put() {     # Datei auf main schreiben: put <pfad im repo> <lokale datei> <nachricht>
  local old; old=$(api "$API/contents/$1" | jq -r '.sha // empty')
  jq -n --arg c "$(base64 < "$2")" --arg m "$3" --arg s "$old" \
    '{content: $c, message: $m, branch: "main"} + if $s == "" then {}
      else {sha: $s} end' \
    | api -X "$([ -n "$old" ] && echo PUT || echo POST)" "$API/contents/$1" -d @- \
    | jq -r '"✔ \(.content.path) @ \(.commit.sha[0:7])"'
}
