# helpers.sh – Kurzbefehle für Tag 11. Laden mit:
#   source ~/renovate-lab/code/tag11/helpers.sh
API="$FORGEJO/api/v1"
api() { curl -sf -u "$ADMIN" -H 'Content-Type: application/json' "$@"; }
# Datei per API anlegen oder ersetzen: putfile <org/repo> <pfad> <lokale-datei>
putfile() {
  local sha method=POST
  sha=$(api "$API/repos/$1/contents/$2" 2>/dev/null | jq -r '.sha // empty')
  [ -n "$sha" ] && method=PUT
  jq -n --rawfile c "$3" --arg s "$sha" --arg m "$2 aktualisiert" \
    '{content: ($c | @base64), message: $m} + if $s == "" then {} else {sha: $s} end' \
    | api -X "$method" "$API/repos/$1/contents/$2" -d @- >/dev/null \
    && echo "✔ $1: $2"
}
# offene PRs mit Labels und Reviewern: prs <org/repo>
prs() { api "$API/repos/$1/pulls?state=open&limit=50" | jq -r 'sort_by(.number)[]
  | "#\(.number) \(.title) [\([.labels[].name] | join(","))]"
    + (if (.requested_reviewers // []) == [] then ""
       else " review: \([.requested_reviewers[].login] | join(","))" end)'; }
# offene Issues: issues <org/repo>
issues() { api "$API/repos/$1/issues?state=open&type=issues" \
  | jq -r '.[] | "#\(.number) \(.title)"'; }
# aufgelöste Repo-Config, nur die Org-Anteile: cfg <org/repo>
cfg() { LOG_FORMAT=json renovate --print-config=true --dry-run=extract "$1" \
  2>/dev/null | jq -r '
    select(.msg == "Full resolved config and hostRules including presets")
    | .config | ({timezone, labels, addLabels, reviewers, postUpdateOptions,
        k8s: .kubernetes.managerFilePatterns} | to_entries[]
        | select(.value != null and .value != [])
        | "\(.key): \(.value | tojson)"),
      (.packageRules[] | .description[0]? // "" | select(startswith("shop:"))
        | "rule: \(.)")'; }
