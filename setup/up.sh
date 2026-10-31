#!/usr/bin/env bash
# up.sh – startet Forgejo (Lab) in Docker, legt Admin, Bot und Bot-Token an.
# Idempotent: mehrfach aufrufbar. Alle Passwörter und Tokens sind Lab-Werte!
set -euo pipefail
NAME="${FORGEJO_NAME:-forgejo}"
PORT="${FORGEJO_PORT:-3000}"
IMAGE="codeberg.org/forgejo/forgejo:16.0.6-rootless"
DIR="$(cd "$(dirname "$0")" && pwd)"
if ! docker ps -a --format '{{.Names}}' | grep -qx "$NAME"; then
  docker run -d --name "$NAME" -p "127.0.0.1:$PORT:3000" \
    -v "$NAME-data:/var/lib/gitea" -v "$NAME-conf:/etc/gitea" \
    -e FORGEJO__security__INSTALL_LOCK=true \
    -e FORGEJO__server__ROOT_URL="http://127.0.0.1:$PORT/" \
    -e FORGEJO__database__DB_TYPE=sqlite3 \
    -e FORGEJO__service__DISABLE_REGISTRATION=true \
    -e FORGEJO__repository__DEFAULT_BRANCH=main \
    "$IMAGE" >/dev/null
fi
docker start "$NAME" >/dev/null
until curl -sf "http://127.0.0.1:$PORT/api/healthz" >/dev/null; do sleep 1; done
fj() { docker exec "$NAME" forgejo admin "$@"; }
users=$(fj user list)
grep -qw lab-admin <<<"$users" || fj user create --admin --username lab-admin \
  --password lab-admin-pw-123 --email admin@lab.local --must-change-password=false
grep -qw renovate-bot <<<"$users" || fj user create --username renovate-bot \
  --password lab-bot-pw-123 --email renovate-bot@lab.local --must-change-password=false
if [ ! -s "$DIR/bot-token" ]; then
  fj user generate-access-token --username renovate-bot --token-name "renovate-$(date +%s)" \
    --scopes write:repository,write:issue,read:user,read:organization,read:package \
    --raw > "$DIR/bot-token"
  chmod 600 "$DIR/bot-token"
fi
echo "✔ Forgejo läuft: http://127.0.0.1:$PORT (lab-admin / lab-admin-pw-123)"
