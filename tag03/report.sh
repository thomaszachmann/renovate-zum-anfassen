# report.sh – Hilfsfunktionen für Renovate-Reports (--report-type=file).
# Laden mit: source ~/renovate-lab/code/tag03/report.sh
#   files <report.json>  welcher Manager hat welche Datei gefunden?
#   deps  <report.json>  Abhängigkeiten mit aktueller Version und Updates
#   dsrc  <report.json>  welcher Manager nutzt welche Datasource/Versioning?
files() {
  jq -r '.repositories | to_entries[] | (.key | sub("^shop/"; "")) as $r
    | .value.packageFiles | to_entries[] | .key as $m | .value[]
    | [$r, $m, .packageFile] | @tsv' "$1" | column -t
}
deps() {
  jq -r '.repositories | to_entries[] | (.key | sub("^shop/"; "")) as $r
    | .value.packageFiles | to_entries[] | .key as $m | .value[] | .deps[]
    | [$r, $m, .depName, .currentValue,
       ([.updates[]?.newVersion] | join(",") | if . == "" then "-" else . end)]
    | @tsv' "$1" | column -t
}
dsrc() {
  jq -r '[.repositories[].packageFiles | to_entries[] | .key as $m | .value[]
    | . as $f | .deps[] | [$m, (.datasource // $f.datasource), .versioning]]
    | unique[] | @tsv' "$1" | column -t
}
