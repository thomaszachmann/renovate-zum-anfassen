# helpers.sh – Kurzbefehle für Tag 13. Laden mit: source ~/renovate-lab/tag13/helpers.sh
R="$FORGEJO/api/v1/repos/shop/shop-mono"
api() { curl -sf -u "$ADMIN" -H 'Content-Type: application/json' "$@"; }
# PRs: Nummer, Ziel-Branch, Quell-Branch (ohne renovate/), Titel: prs [open|closed]
prs() { api "$R/pulls?state=${1:-open}&limit=50" | jq -r 'sort_by(.number)[]
  | "#\(.number) \(.base.ref) <- \(.head.ref | ltrimstr("renovate/"))  \(.title)"'; }
# Nummer des ersten offenen PRs, dessen Titel auf ein Muster passt: pr lodash
pr() { api "$R/pulls?state=open&limit=50" | jq -r --arg p "$1" \
  '[sort_by(.number)[] | select(.title | test($p))][0].number'; }
# geänderte Dateien eines PRs mit +/-: files <nr>
files() { api "$R/pulls/$1/files" \
  | jq -r '.[] | "\(.filename) +\(.additions) -\(.deletions)"'; }
# Labels, Assignees und Reviewer eines PRs: meta <nr>
meta() { api "$R/pulls/$1" | jq -r '"#\(.number) labels=\([.labels[].name]|join(","))"
  + " assignees=\([.assignees[]?.login]|join(","))"
  + " reviewers=\([.requested_reviewers[]?.login]|join(","))"'; }
# letzte Commit-Nachricht eines Branches: msg renovate/dayjs-1.x
msg() { api "$R/commits?sha=$1&limit=1" | jq -r '.[0].commit.message'; }
# Rebase-Checkbox im PR abhaken, Renovate baut den Branch neu: rebase <nr>
rebase() { api "$R/pulls/$1" | jq -r .body \
  | sed 's|- \[ \] <!-- rebase-check -->|- [x] <!-- rebase-check -->|' \
  | jq -Rs '{body: .}' | api -X PATCH "$R/pulls/$1" -d @- >/dev/null \
  && echo "#$1 zum Rebase markiert"; }
# Labels für den Tag im Repo anlegen (Forgejo verwirft unbekannte Labels still)
mklabels() { for l in deps:1d76db web:0e8a16 worker:5319e7 go:00add8 backport:d93f0b; do
  api -X POST "$R/labels" -d "{\"name\":\"${l%%:*}\",\"color\":\"#${l##*:}\"}" \
    | jq -r .name; done | paste -sd' ' -; }
# renovate.json per jq-Filter ändern: cfg '.labels = ["deps"]'
cfg() { jq "$1" renovate.json > renovate.tmp && mv renovate.tmp renovate.json; }
# renovate.json prüfen, alles committen und pushen: ship "Nachricht"
ship() { renovate-config-validator --no-global renovate.json >/dev/null \
  && git add -A && git commit -qm "$1" && git push -q origin HEAD && echo "✔ $1"; }
