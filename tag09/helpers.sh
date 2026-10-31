# helpers.sh – Kurzbefehle für Tag 9. Laden mit: source ~/renovate-lab/tag09/helpers.sh
api() { curl -sf -u "$ADMIN" -H 'Content-Type: application/json' "$@"; }
# Datei per API anlegen/ersetzen: put <org/repo> <pfad im repo> <lokale datei> <msg>
put() { local sha m=POST
  sha=$(api "$FORGEJO/api/v1/repos/$1/contents/$2" | jq -r '.sha // empty')
  [ -n "$sha" ] && m=PUT
  jq -n --arg c "$(base64 < "$3")" --arg s "$sha" --arg m "$4" \
    '{content: $c, message: $m} + (if $s == "" then {} else {sha: $s} end)' \
    | api -X "$m" "$FORGEJO/api/v1/repos/$1/contents/$2" -d @- \
    | jq -r '"✔ \(.content.path) @ \(.commit.sha[0:7])"'; }
# PRs eines Repos: prs <org/repo> [open|closed|all]
prs() { api "$FORGEJO/api/v1/repos/$1/pulls?state=${2:-open}&limit=50" \
  | jq -r 'sort_by(.number)[] | "#\(.number) \(.state) \(.head.ref) | \(.title)"'; }
# Datei auf einem Branch lesen: raw <org/repo> <branch> <pfad>
raw() { api "$FORGEJO/api/v1/repos/$1/raw/$3?ref=$2"; }
# Laufzusammenfassung aus einem JSON-Log: summary <logdatei>
summary() { jq -r 'select(.msg == "Repository finished")
  | "\(.repository)\t\(.durationMs) ms\tcloned=\(.cloned)\t\(.result // "-")"' "$1"; }
# Ergebnis je Repo aus einem normalen (Pretty-)Log: results <logdatei>
results() { grep -E 'Repository started|"result"' "$1" | sed -E \
  's/.*repository=([^)]*)\).*/\1/; s/ *"result": "([^"]*)",?/\1/' | paste - -; }
