# creds.sh – Zugangsdaten für Renovate auf Admin-Seite (gehört NICHT ins Repo!)
# Laden mit: source ~/renovate-lab/tag08/creds.sh
T=$(cat ~/renovate-lab/setup/bot-token)                 # Lab-Wert!
export RENOVATE_HOST_RULES=$(jq -nc --arg t "$T" '[
  {matchHost: "http://127.0.0.1:3000/api/packages/", hostType: "npm", token: $t},
  {matchHost: "127.0.0.1", hostType: "docker", username: "renovate-bot",
   password: $t, insecureRegistry: true}
]')
unset T
