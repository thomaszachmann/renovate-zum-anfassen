# kontrolle.sh – Kontrollpunkt Tag 13. Aufruf in ~/renovate-lab/tag13: bash kontrolle.sh
source helpers.sh
c() { if eval "$2" >/dev/null 2>&1; then echo "✔ $1"; else echo "✘ $1"; fi; }
B=renovate/main-worker-github.com-pkg-errors-0.x
c "Extract fand 3 package.json und 1 go.mod" \
  "[ \$(jq '[.repositories[].packageFiles[][]] | length' extract.json) -eq 4 ]"
c "lodash-PR ändert beide Workspaces und das Root-Lockfile" \
  "[ \$(files \$(pr 'lodash.*main') | wc -l) -eq 3 ]"
c "Worker-PR trägt Label worker und Präfix worker-" \
  "meta \$(pr 'pkg/errors.*main') | grep -q worker && prs | grep -q main-worker-"
c "go.sum im Worker-PR ohne Altlast v0.9.0 (gomodTidy)" \
  "! api \"\$R/raw/services/worker/go.sum?ref=\$B\" | grep -q 'errors v0.9.0'"
c "Lock file maintenance gegen main offen" "[ \$(pr 'lock file.*main') != null ]"
c "semantischer Titel mit Scope worker" "prs | grep -q 'build(worker): bump'"
c "PRs gegen release/1.x vorhanden" "prs | grep -q '^#[0-9]* release/1.x'"
c "alice als Reviewer eingetragen" \
  "meta \$(pr 'dayjs.*main') | grep -q 'reviewers=alice'"
