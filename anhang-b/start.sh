#!/usr/bin/env bash
# start.sh – Startzustand der Abschlussprüfung (Anhang B). Mehrfach aufrufbar:
# legt Org billing mit billing-api, billing-worker und renovate-config neu an
# und leert ~/renovate-lab/pruefung.
set -euo pipefail
LAB="${LAB:-$HOME/renovate-lab}"
source "$LAB/setup/env.sh"
HERE="$(cd "$(dirname "$0")" && pwd)"
api() { curl -sf -u "$ADMIN" -H 'Content-Type: application/json' "$@"; }
for r in renovate-config billing-api billing-worker; do
  "$LAB/setup/mkrepo.sh" "billing/$r" "$HERE/$r" >/dev/null
done
# Kein Runner im Lab: Forgejo Actions aus, sonst hängt jeder Check auf pending
api -X PATCH "$FORGEJO/api/v1/repos/billing/billing-api" \
  -d '{"has_actions":false}' >/dev/null
rm -rf "$LAB/pruefung" && mkdir -p "$LAB/pruefung"      # Achtung: leert den Ordner
echo "✔ billing/renovate-config, billing/billing-api, billing/billing-worker angelegt"
echo "✔ Ordner pruefung geleert"
