#!/usr/bin/env bash
# loesung.sh – spielt die Musterlösung der Abschlussprüfung durch (Anhang B).
# Vorher: start.sh. Dauer ca. 5 min (der erste Lauf lädt die OSV-Datenbank).
set -euo pipefail
LAB="${LAB:-$HOME/renovate-lab}"
source "$LAB/setup/env.sh"
L="$(cd "$(dirname "$0")" && pwd)"; P="$LAB/pruefung"; cd "$P"
A="$FORGEJO/api/v1/repos/billing"
GIT="http://$ADMIN@127.0.0.1:$FORGEJO_PORT/billing"
api() { curl -sf -u "$ADMIN" -H 'Content-Type: application/json' "$@"; }
lauf() { renovate > "lauf-$1.log" 2>&1; echo "✔ Lauf $1"; }
nr() { api "$A/$1/issues?state=open&limit=50" \
  | jq -r --arg t "$2" '[.[] | select(.title | test($t))][0].number'; }
merge() { local n; n=$(nr billing-api "$1")       # merge <titel-regex>
  for _ in 1 2 3 4 5; do       # Forgejo prüft nach jedem Merge kurz neu
    api -X POST "$A/billing-api/pulls/$n/merge" \
      -d '{"Do":"merge","delete_branch_after_merge":true}' && break; sleep 3
  done; echo "✔ PR #$n gemergt ($1)"; }
push() { rm -rf "$P/$1" && git clone -q "$GIT/$1.git" "$P/$1"   # push <repo> <q> <z>
  cp "$2" "$P/$1/$3" && (cd "$P/$1" && renovate-config-validator --no-global "$3" \
    >/dev/null && git add "$3" && git -c user.name="Lab Admin" \
    -c user.email=admin@lab.local commit -qm "Renovate-Config aktualisiert" \
    && git push -q) && echo "✔ $1: $3"; }
fehler() { api "$A/billing-worker/issues/$(nr billing-worker 'Action Required')" \
  | jq -r .body | grep -E '^(Message|Error type):'; }

# A1 Preset-Repo, Bot nur lesend
push renovate-config "$L/default.json" default.json
api -X PUT "$A/renovate-config/collaborators/renovate-bot" -d '{"permission":"read"}'
# A2 globale config.js (Endpoint aus env.sh)
sed "s|http://127.0.0.1:3000/api/v1|$RENOVATE_ENDPOINT|" "$L/config.js" > config.js
lauf 1
# A9 Teil 1: erster Fehler aus dem Issue, dann reparieren
echo "Lauf 1: $(fehler)" > diagnose.txt
sed 's/"prConcurrentLimit": "4"/"prConcurrentLimit": 4/' \
  "$L/../billing-worker/renovate.json" > "$P/worker-zwischen.json"
push billing-worker "$P/worker-zwischen.json" renovate.json
# A3 Onboarding mergen, A4/A5/A7/A8: eigene Regeln für billing-api
merge 'Configure Renovate'
push billing-api "$L/billing-api.json" renovate.json
lauf 2
echo "Lauf 2: $(fehler)" >> diagnose.txt
push billing-worker "$L/billing-worker.json" renovate.json
# A6 Security-PR und Pin-PR mergen
merge 'SECURITY'; merge 'Pin dependencies'
lauf 3
# A7 Status per API, A8 Freigabe per Checkbox im Dashboard
sha=$(api "$A/billing-api/branches/renovate%2Fdev-tools" | jq -r .commit.id)
api -X POST "$A/billing-api/statuses/$sha" \
  -d '{"state":"success","context":"ci/test","description":"Lab-CI"}' >/dev/null
d=$(nr billing-api 'Dependency Dashboard')
m='<!-- approve-branch=renovate/express-5.x -->'
api "$A/billing-api/issues/$d" | jq -r .body | sed "s|- \\[ \\] $m|- [x] $m|" \
  | jq -Rs '{body: .}' | api -X PATCH "$A/billing-api/issues/$d" -d @- >/dev/null
lauf 4
echo "✔ Musterlösung durchgespielt"
