# helpers.sh – Kurzbefehle für Tag 12. Laden mit: source helpers.sh
# Aufruf im Klon ~/renovate-lab/tag12/shop-api, Logs landen eine Ebene höher.
R="$FORGEJO/api/v1/repos/shop/shop-api"
api() { curl -sf -u "$ADMIN" -H 'Content-Type: application/json' "$@"; }
# offene PRs: Nummer, Branch ohne renovate/, Titel, [Labels]
prs() { api "$R/pulls?state=open&limit=50" | jq -r 'sort_by(.number)[]
  | "#\(.number) \(.head.ref | sub("^renovate/"; "")): \(.title)"
    + ([.labels[].name] | if length > 0 then " [\(join(","))]" else "" end)'; }
# PR-Objekt zum Branch: _pr prettier-3.x
_pr() { api "$R/pulls?state=open&limit=50" \
  | jq -c --arg b "renovate/$1" '.[] | select(.head.ref == $b)'; }
# Text eines PRs: body npm-express-vulnerability
body() { _pr "$1" | jq -r .body; }
# Kommentare eines PRs: comments prettier-3.x
comments() { api "$R/issues/$(_pr "$1" | jq -r .number)/comments" \
  | jq -r '.[].body'; }
# Status-Checks am Branch-Kopf: checks prettier-3.x
checks() { local sha
  sha=$(api "$R/branches/renovate/$1" | jq -r .commit.id)
  api "$R/commits/$sha/status" | jq -r '.statuses[]
    | "\(.context): \(.status) – \(.description)"'; }
# PR eines Branches mergen und main aktualisieren: merge pin-dependencies
merge() { api -X POST "$R/pulls/$(_pr "$1" | jq -r .number)/merge" \
    -d '{"Do":"merge","delete_branch_after_merge":true}' \
  && git pull -q && echo "✔ renovate/$1 gemergt"; }
# Rebase-Checkbox im PR setzen: rebase prettier-3.x
rebase() { local pr; pr=$(_pr "$1")
  api -X PATCH "$R/pulls/$(jq -r .number <<<"$pr")" \
    -d "$(jq '{body: (.body | sub("- \\[ \\] <!-- rebase-check -->";
      "- [x] <!-- rebase-check -->"))}' <<<"$pr")" >/dev/null \
    && echo "✔ Rebase angefordert: $1"; }
# Geänderte Zeilen eines Renovate-Branches: diffb pin-dependencies
diffb() { git fetch -q --prune origin
  git diff "origin/main...origin/renovate/$1" -- . ':!package-lock.json' \
    | grep -E '^[-+][^-+]'; }
# Text des Dependency Dashboards
dash() { api "$R/issues?state=open&type=issues&limit=50" \
  | jq -r '.[] | select(.title == "Dependency Dashboard") | .body'; }
# renovate.json prüfen, alles committen und pushen: ship "Nachricht"
ship() { renovate-config-validator --no-global renovate.json >/dev/null \
  && git add -A && git commit -qm "$1" && git push -q origin main && echo "✔ $1"; }
# echter Lauf, Log nach ../lauf-<name>.log, nur Ergebniszeilen: run <name>
run() { renovate shop/shop-api > "../lauf-${1:-x}.log" 2>&1
  grep -hoE 'Branch (created|updated)|PR (created|updated)|Autoclosing PR' \
    "../lauf-${1:-x}.log" | sort | uniq -c; }
