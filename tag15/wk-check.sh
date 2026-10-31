#!/usr/bin/env bash
# wk-check.sh – Wettkampf-Matrix (Tag 15): eine Zeile ✔/✘ pro Runde.
# Exit-Code = Anzahl offener Runden.
LAB="${LAB:-$HOME/renovate-lab}"
source "$LAB/setup/env.sh"
W="$LAB/tag15"; fail=0; n=0
api() { curl -sf -u "$ADMIN" "$@"; }
R() { echo "$FORGEJO/api/v1/repos/shop/$1"; }
open_prs() { api "$(R "$1")/pulls?state=open&limit=50"; }
dash() { api "$(R "$1")/issues?type=issues&state=open&limit=50" \
  | jq -r '.[] | select(.title == "Dependency Dashboard") | .body'; }
t() { n=$((n + 1)); if eval "$2" >/dev/null 2>&1; then echo "✔ $1"
      else echo "✘ $1"; fail=$((fail + 1)); fi; }

t "R1 kasse: Config gültig, kein Action-Required-Issue, PRs offen" \
  "api \$(R kasse)/raw/renovate.json | jq -e . \
   && ! api \"\$(R kasse)/issues?type=issues&state=open\" \
        | jq -e '.[] | select(.title | startswith(\"Action Required\"))' \
   && open_prs kasse | jq -e 'length > 0'"
t "R2 wk-token: gültig, Scopes reichen, kein Admin-Scope" \
  "T=\$(cat $W/wk-token); \
   curl -sf -H \"Authorization: token \$T\" $FORGEJO/api/v1/user \
     | jq -e '.login == \"renovate-bot\"' \
   && curl -sf -u renovate-bot:lab-bot-pw-123 \
        $FORGEJO/api/v1/users/renovate-bot/tokens | jq -e --arg e \"\${T: -8}\" \
        '.[] | select(.token_last_eight == \$e) | .scopes
         | (contains([\"write:repository\",\"write:issue\",\"read:user\",
                      \"read:organization\"]) and (index(\"all\") | not)
            and (map(select(test(\"admin\"))) | length == 0))'"
t "R3 werkzeug: Makefile-Werkzeuge im Dashboard" \
  "dash werkzeug | grep -q 'markdownlint-cli2' && dash werkzeug | grep -q 'redocly'"
t "R4 automat: prettier-PR gemergt, Actions aus, ci/test ist Pflicht" \
  "api \"\$(R automat)/pulls?state=closed&limit=50\" | jq -e '.[] \
     | select(.merged and (.title | test(\"prettier\")))' \
   && api \$(R automat) | jq -e '.has_actions == false' \
   && api \$(R automat)/branch_protections | jq -e '.[] | select(.rule_name == \"main\"
        and .enable_status_check and (.status_check_contexts | index(\"ci/test\")))'"
t "R5 flut: höchstens 6 PRs offen, Sammel-PR da, Altlast autoclosed" \
  "open_prs flut | jq -e 'length <= 6' \
   && open_prs flut | jq -e '[.[] | .body | [scan(\"(?m)^\\\\| \\\\[\")] | length]
        | max >= 3' \
   && api \"\$(R flut)/pulls?state=closed&limit=50\" \
        | jq -e '[.[] | select(.title | endswith(\"- autoclosed\"))] | length > 0'"
t "R6 major: express-Major-PR wieder offen" \
  "open_prs major | jq -e '.[] | select(.head.ref == \"renovate/express-5.x\")'"
t "R7 bezahlung: Lookup klappt, PR für @shop/money offen" \
  "! dash bezahlung | grep -q 'Failed to look up' \
   && open_prs bezahlung | jq -e '.[] | select(.title | test(\"@shop/money\"))'"
t "R8 lager (Bonus): offene PRs ohne Artefakt-Fehler" \
  "open_prs lager | jq -e 'length > 0' && (for b in \$(open_prs lager \
     | jq -r '.[].head.ref'); do api \"\$(R lager)/commits/\${b//\\//%2F}/status\" \
     | jq -e '[.statuses[]? | select(.context == \"renovate/artifacts\"
        and .status == \"failure\")] | length == 0' || exit 1; done)"
echo "Gelöst: $((n - fail)) von $n"
exit "$fail"
