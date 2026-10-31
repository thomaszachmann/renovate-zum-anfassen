# env.sh – Umgebung für Renovate im Lab. Laden mit: source ~/renovate-lab/setup/env.sh
LAB="${LAB:-$HOME/renovate-lab}"
export PATH="$LAB/tools/node_modules/.bin:$PATH"
export FORGEJO_PORT="${FORGEJO_PORT:-3000}"
export FORGEJO="http://127.0.0.1:$FORGEJO_PORT"
export ADMIN="lab-admin:lab-admin-pw-123"            # Lab-Wert!
export RENOVATE_PLATFORM=forgejo
export RENOVATE_ENDPOINT="$FORGEJO/api/v1"
export RENOVATE_TOKEN="$(cat "$LAB/setup/bot-token" 2>/dev/null)"
export RENOVATE_GIT_AUTHOR="Renovate Bot <renovate-bot@lab.local>"
export LOG_LEVEL="${LOG_LEVEL:-info}"
