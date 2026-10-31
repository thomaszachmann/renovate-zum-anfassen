# rezepte.sh – jq-Rezepte für JSON-Logs. Laden mit: source rezepte.sh
# Alle Funktionen lesen eine Logdatei aus LOG_LEVEL=debug LOG_FORMAT=json.
levels() {   # Einträge pro Level: levels <log>
  jq -r '.level' "$1" | sort | uniq -c
}
probleme() { # alles ab WARN: probleme <log>
  jq -r 'select(.level >= 40) | "\(.level) \(.branch // "-") \(.msg)"
    + (if .err then " | \(.err.validationError // .err.message
         | split("\n")[0])" else "" end)' "$1"
}
updates() {  # gefundene Updates pro Abhängigkeit: updates <log>
  jq -r 'select(.msg == "packageFiles with updates") | .config[][]
    | .packageFile as $f | .deps[] | "\($f): \(.depName) \(.currentValue // "")"
      + " -> \([.updates[]? | "\(.newVersion) (\(.updateType))"] | join(", "))"
      + (if .skipReason then " [skip: \(.skipReason)]" else "" end)
      + ([.warnings[]?.message] | if length > 0 then " [warn: \(.[0])]"
         else "" end)' "$1"
}
branches() { # Entscheidung pro Branch: branches <log>
  jq -r 'select(.msg == "branches info extended") | .branchesInformation[]
    | "\(.result)\t#\(.prNo // "-")\t\(.branchName)"' "$1"
}
warum() {    # alle Debug-Meldungen zu einem Branch: warum <log> <branch-ohne-prefix>
  jq -r --arg b "renovate/$2" 'select(.branch == $b) | .msg' "$1"
}
