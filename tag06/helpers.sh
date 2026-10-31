# helpers.sh – Kurzbefehle für Tag 6. Laden mit: source helpers.sh
# Aufruf im Klon ~/renovate-lab/tag06/shop-api, Logs landen eine Ebene höher.
R="$FORGEJO/api/v1/repos/shop/shop-api"
api() { curl -sf -u "$ADMIN" -H 'Content-Type: application/json' "$@"; }
# offene PRs: Nummer, Branch, Titel
prs() { api "$R/pulls?state=open&limit=50" \
  | jq -r 'sort_by(.number)[] | "#\(.number) \(.head.ref) | \(.title)"'; }
# PR mergen: merge <nr>
merge() { api -X POST "$R/pulls/$1/merge" \
  -d '{"Do":"merge","delete_branch_after_merge":true}' \
  && git checkout -q main && git pull -q \
  && echo "✔ PR #$1 gemergt"; }
# renovate.json prüfen, alles committen und pushen: ship "Nachricht"
ship() { renovate-config-validator --no-global renovate.json >/dev/null \
  && git add -A && git commit -qm "$1" \
  && git push -q origin HEAD 2>/dev/null && echo "✔ $1"; }
# renovate.json per jq-Filter ändern und pushen: cfg '.rangeStrategy = "pin"'
cfg() { jq "$1" renovate.json > renovate.tmp && mv renovate.tmp renovate.json \
  && ship "Konfiguration $1"; }
# echter Lauf, nur Ergebniszeilen zeigen: run <name>
run() { renovate shop/shop-api > "../lauf-${1:-x}.log" 2>&1
  grep -hoE 'Branch (created|updated)|PR (created|updated)|Autoclosing PR' \
    "../lauf-${1:-x}.log" | sort | uniq -c; }
# geänderte Zeilen jedes Renovate-Branches (package.json, Dockerfile)
diffs() { git fetch -q --prune origin
  for b in $(git branch -r --format='%(refname:short)' | grep '/renovate/'); do
    echo "== ${b#origin/}"
    git diff "origin/main...$b" -- package.json Dockerfile \
      | grep -E '^[-+][^-+]' | sed -E 's/(sha256:.{12})[0-9a-f]+/\1…/' \
      | grep . || echo "   (nur package-lock.json)"
  done; }
# Vorschau ohne Branches: Paket, Wert, Versioning, Updates
look() { renovate --dry-run=lookup --report-type=file --report-path=../look.json \
    shop/shop-api > ../look.log 2>&1
  jq -r '.repositories[].packageFiles[][].deps[] | [.depName, .currentValue,
      (.versioning // "-" | sub("^regex:.*"; "regex")),
      ([.updates[]? | "\(.updateType): \(.newValue // "")"
        + (if (.newValue // "" | test("^[~^<>=]")) then " (\(.newVersion))"
           else "" end)]
       | join(", ") | if . == "" then "-" else . end)] | @tsv' ../look.json \
    | column -t -s $'\t'; }
