#!/usr/bin/env bash
# bewertung.sh – wertet die praktische Abschlussprüfung aus (Anhang B)
# Aufruf: ~/renovate-lab/code/anhang-b/bewertung.sh   (Laufzeit unter 1 min)
LAB="${LAB:-$HOME/renovate-lab}"
source "$LAB/setup/env.sh"
P="$LAB/pruefung"; cd "$P" || exit 2
A="$FORGEJO/api/v1/repos/billing"
api() { curl -sf -u "$ADMIN" "$@"; }
raw() { api "$FORGEJO/billing/$1/raw/branch/$2/$3"; }       # raw <repo> <ref> <datei>
T=$(mktemp -d)
declare -a pts=(0 0 0 0 0 0 0 0 0 0)
pt() {  # pt <aufgabe> <punkte> <text> <befehl...>
  local a=$1 p=$2 t=$3; shift 3
  if "$@" >/dev/null 2>&1; then
    echo "✔ A$a $t (+$p)"; pts[a]=$((pts[a] + p))
  else
    echo "✘ A$a $t (0 von $p)"
  fi
}
# Aufgelöste Config und Laufergebnis je Repo, ohne etwas zu verändern
for r in billing-api billing-worker; do
  (cd "$T" && LOG_FORMAT=json renovate --print-config=true --dry-run=extract \
    "billing/$r" > "$T/$r.log" 2>&1)
  jq -c 'select(.msg == "Full resolved config and hostRules including presets")
    | .config' "$T/$r.log" > "$T/$r.cfg"
done
cfg() { jq -e "$1" "$T/billing-api.cfg"; }
rule() { cfg ".packageRules | any($1)"; }
prs() { api "$A/billing-api/pulls?state=all&limit=50"; }
pr() { prs | jq -e ".[] | select($1)"; }
extends() { raw "$1" main renovate.json \
  | jq -e '.extends | index("local>billing/renovate-config")'; }
# A1
preset() { raw renovate-config main default.json > "$T/default.json" \
  && renovate-config-validator --no-global "$T/default.json"; }
readonly_bot() { curl -sf -H "Authorization: token $RENOVATE_TOKEN" \
  "$A/renovate-config" | jq -e '.permissions | .pull and (.push | not)'; }
# A2
discovered() { rm -f "$T/repos.json"
  renovate --write-discovered-repos="$T/repos.json" \
  && jq -e '. == ["billing/billing-api","billing/billing-worker"]' "$T/repos.json"; }
onbcfg() { node -e 'const c = require(process.argv[1]);
  process.exit(c.onboardingConfig.extends.includes("local>billing/renovate-config")
  ? 0 : 1)' "$P/config.js"; }
# A5, A6, A7
kubectl_pr() { pr '.title | test("kubernetes/kubernetes")'; }
kubectl_new() { local b; b=$(prs | jq -r '[.[] | select(.title
    | test("kubernetes/kubernetes"))][0].head.ref')
  raw billing-api "$b" Dockerfile | grep -E '^ARG KUBECTL_VERSION=v' \
    | grep -vq 'v1.29.0$'; }
pinned() { raw billing-api main .github/workflows/ci.yml \
  | grep -cE "uses: actions/(checkout|setup-node)@[0-9a-f]{40}$1" | grep -qx 2; }
devtools() { prs | jq -e '.[] | select(.head.label == "renovate/dev-tools")'; }
automerged() { local n; n=$(prs | jq -r '[.[] | select(.head.label
    == "renovate/dev-tools")][0].number')
  api "$A/billing-api/pulls/$n" | jq -e '.merged_by.login == "renovate-bot"'; }
green() { local s
  s=$(prs | jq -r '[.[] | select(.head.label == "renovate/dev-tools")][0].head.sha')
  api "$A/billing-api/commits/$s/status" | jq -e '.state == "success"'; }
node_open() { ! pr '(.title | test("Node.js")) and .merged'; }
nomajor() { cfg '(.automerge | not) and (.packageRules | all((.automerge | not)
  or ((.matchUpdateTypes // []) | length > 0 and (index("major") | not))))'; }
# A9
worker_done() { jq -r .msg "$T/billing-worker.log" > "$T/w.txt"
  grep -qx 'Dependency extraction complete' "$T/w.txt" \
    && ! grep -q 'invalid config' "$T/w.txt"; }
no_issue() { ! api "$A/billing-worker/issues?state=open&type=issues" \
  | jq -e '.[] | select(.title | test("Action Required"))'; }
diagnose() { grep -q prConcurrentLimit diagnose.txt \
  && grep -q 'config:recomended' diagnose.txt; }

pt 1 4 "default.json im Preset-Repo gültig" preset
pt 1 3 "Bot liest das Preset-Repo nur" readonly_bot
pt 1 3 "billing-api erbt timezone Europe/Berlin" cfg '.timezone == "Europe/Berlin"'
pt 2 3 "config.js gültig (global)" renovate-config-validator "$P/config.js"
pt 2 4 "autodiscover findet genau billing-api und billing-worker" discovered
pt 2 3 "onboardingConfig erweitert local>billing/renovate-config" onbcfg
pt 3 2 "Onboarding-PR gemergt" pr '.title == "Configure Renovate" and .merged'
pt 3 3 "billing-api: renovate.json mit local>-Preset" extends billing-api
pt 4 3 "prConcurrentLimit 4" cfg '.prConcurrentLimit == 4'
pt 4 2 "prHourlyLimit 0" cfg '.prHourlyLimit == 0'
pt 4 3 "Gruppe dev-tools für devDependencies" rule '(.groupName == "dev-tools")
  and ((.matchDepTypes // []) | index("devDependencies"))'
pt 4 2 "Branch renovate/dev-tools mit PR" devtools
pt 4 5 "Schedule für dependencies" rule '((.matchDepTypes // [])
  | index("dependencies")) and ((.schedule // []) | length > 0)'
pt 5 5 "PR für kubernetes/kubernetes" kubectl_pr
pt 5 5 "Dockerfile-ARG im PR-Branch angehoben" kubectl_new
pt 6 3 "osvVulnerabilityAlerts aktiv" cfg '.osvVulnerabilityAlerts == true'
pt 6 5 "Security-PR für express gemergt" pr '(.title | test("express.*SECURITY"))
  and .merged'
pt 6 5 "Actions per Digest gepinnt" pinned ''
pt 6 2 "Tag als Kommentar hinter dem Digest" pinned ' # v[0-9]+'
pt 7 4 "kein Automerge für Majors" nomajor
pt 7 6 "dev-tools von Renovate automatisch gemergt" automerged
pt 7 3 "dev-tools-Commit hatte Status success" green
pt 7 2 "Node.js-PR (kein devDep) nicht gemergt" node_open
pt 8 4 "express-Major braucht Freigabe" rule '((.matchPackageNames // [])
  | index("express")) and ((.matchUpdateTypes // []) | index("major"))
  and .dependencyDashboardApproval == true'
pt 8 6 "express-5-PR nach Freigabe vorhanden" \
  pr '.head.label == "renovate/express-5.x"'
pt 9 2 "billing-worker: renovate.json mit local>-Preset" extends billing-worker
pt 9 4 "billing-worker: Lauf ohne Config-Fehler" worker_done
pt 9 1 "kein offenes Issue Action Required" no_issue
pt 9 3 "diagnose.txt nennt beide Fehler" diagnose
rm -rf "$T"
sum=0; for a in 1 2 3 4 5 6 7 8 9; do sum=$((sum + pts[a])); done
echo "Summe: $sum von 100 (Pflichtaufgabe 6: ${pts[6]} von 15)"
if [ "$sum" -ge 70 ] && [ "${pts[6]}" -eq 15 ]; then
  echo "✔ BESTANDEN"
else
  echo "✘ NICHT BESTANDEN"
fi
