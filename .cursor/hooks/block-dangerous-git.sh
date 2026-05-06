#!/usr/bin/env bash
set -euo pipefail

input="$(cat)"

if ! command -v jq >/dev/null 2>&1; then
  echo '{ "permission": "allow" }'
  exit 0
fi

cmd="$(echo "$input" | jq -r '.command // empty')"

dangerous_patterns=(
  '^git[[:space:]]+push($|[[:space:]])'
  '^git[[:space:]]+reset[[:space:]]+--hard($|[[:space:]])'
  '^git[[:space:]]+clean[[:space:]]+-f($|[[:space:]])'
  '^git[[:space:]]+clean[[:space:]]+-fd($|[[:space:]])'
  '^git[[:space:]]+branch[[:space:]]+-D($|[[:space:]])'
  '^git[[:space:]]+(checkout|restore)[[:space:]]+\\.(\\s|$)'
)

for pattern in "${dangerous_patterns[@]}"; do
  if echo "$cmd" | grep -Eq "$pattern"; then
    echo "$(cat <<'JSON'
{
  "permission": "deny",
  "user_message": "Blocked dangerous git command. If you really want to run it, run it yourself outside the agent.",
  "agent_message": "Blocked by repo hook: dangerous git command pattern matched."
}
JSON
)"
    exit 0
  fi
done

echo '{ "permission": "allow" }'
exit 0

