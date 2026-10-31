# wk.sh – Helfer für den Wettkampf (Tag 15). Laden mit: source wk.sh
# Alle Befehle nehmen den Repo-Namen ohne Org: prs flut, dash major, ...
api() { curl -sf -u "$ADMIN" -H 'Content-Type: application/json' "$@"; }
R() { echo "$FORGEJO/api/v1/repos/shop/$1"; }
prs() {     # PRs: prs <repo> [open|closed|all]
  api "$(R "$1")/pulls?state=${2:-open}&limit=50" | jq -r 'sort_by(.number)[]
    | "#\(.number) \(if .merged then "merged" else .state end)"
      + " \(.head.ref) | \(.title)"' | cut -c1-88
}
issues() {  # Issues ohne PRs: issues <repo> [open|closed|all]
  api "$(R "$1")/issues?type=issues&state=${2:-open}&limit=50" \
    | jq -r '.[] | "#\(.number) \(.state) \(.title)"'
}
body() { api "$(R "$1")/issues/$2" | jq -r .body; }      # body <repo> <nr>
dashnr() {  # Nummer des Dependency Dashboards: dashnr <repo>
  api "$(R "$1")/issues?type=issues&state=open&limit=50" \
    | jq -r '[.[] | select(.title == "Dependency Dashboard")][0].number'
}
dash() { body "$1" "$(dashnr "$1")"; }                  # dash <repo>
tick() {    # Checkbox abhaken: tick <repo> <nr> <marker aus dem HTML-Kommentar>
  body "$1" "$2" | sed "s|- \[ \] <!-- $3 -->|- [x] <!-- $3 -->|" \
    | jq -Rs '{body: .}' | api -X PATCH "$(R "$1")/issues/$2" -d @- >/dev/null
}
checks() {  # Status-Checks eines Branches: checks <repo> <branch>
  api "$(R "$1")/commits/${2//\//%2F}/status" | jq -r '"gesamt: \(.state)",
    ((.statuses // [])[] | "  \(.context) = \(.status) (\(.description))")'
}
klon() {    # Repo frisch klonen und hineinwechseln: klon <repo>
  cd "$LAB/tag15" && rm -rf "$1"
  git clone -q "http://$ADMIN@127.0.0.1:$FORGEJO_PORT/shop/$1.git" && cd "$1"
  git config user.name "Lab Admin" && git config user.email admin@lab.local
}
ship() {    # renovate.json prüfen, committen, pushen: ship "Nachricht"
  renovate-config-validator >/dev/null && git add -A && git commit -qm "$1" \
    && git push -q origin main && echo "✔ $1"
}
ci() {      # Lab-CI meldet Status: ci <repo> <branch> <pending|success|failure> [ctx]
  local sha; sha=$(api "$(R "$1")/commits?sha=$2&limit=1" | jq -r '.[0].sha')
  api -X POST "$(R "$1")/statuses/$sha" -d "{\"state\":\"$3\",\
\"context\":\"${4:-ci/test}\",\"description\":\"Lab-CI\"}" \
    | jq -r '"\(.context) = \(.status)"'
}
