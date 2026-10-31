# vals.sh – Hilfsfunktion für Tag 7. Laden mit: source ~/renovate-lab/code/tag07/vals.sh
#   vals <report.json>  eigene Abhängigkeiten (Manager regex und jsonata):
#                       Datei, depName, aktueller Wert, neue Werte (newValue)
vals() {
  jq -r '.repositories[].packageFiles | to_entries[]
    | select(.key == "regex" or .key == "jsonata") | .value[]
    | .packageFile as $f | .deps[]
    | [$f, .depName, .currentValue,
       ([.updates[]?.newValue] | join(",") | if . == "" then "-" else . end)]
    | @tsv' "$1" | column -t
}
