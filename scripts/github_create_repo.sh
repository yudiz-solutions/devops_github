#!/usr/bin/env bash
###############################################################################
# github_create_repo.sh
# Creates a repo and optionally invites a collaborator with a given role.
# Usage: ./github_create_repo.sh <owner> <repo_name> [username] [role]
# Role defaults to "push" (write). Options: pull, triage, push, maintain, admin
###############################################################################
set -euo pipefail
readonly API_BASE="${GITHUB_API_URL:-https://api.github.com}"

usage() { echo "Usage: $(basename "$0") <owner> <repo_name> [username] [role]"; exit 1; }
[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && usage
[[ $# -lt 2 ]] && usage
check_env() { [[ -z "${GITHUB_TOKEN:-}" ]] && echo "[ERROR] GITHUB_TOKEN not set" >&2 && exit 1; }

gh_api() {
  local method="$1" endpoint="$2" body="${3:-}"
  local -a args=(--silent --show-error --fail-with-body -X "$method"
    -H "Accept: application/vnd.github+json" -H "Authorization: Bearer ${GITHUB_TOKEN}"
    -H "X-GitHub-Api-Version: 2022-11-28" "${API_BASE}${endpoint}")
  [[ -n "$body" ]] && args+=(-H "Content-Type: application/json" -d "$body")
  curl "${args[@]}"
}

main() {
  local owner="$1" repo_name="$2" collaborator="${3:-}" role="${4:-push}"
  check_env

  echo "[INFO] Checking owner type for '${owner}'..."
  local owner_type
  owner_type=$(gh_api GET "/users/${owner}" | grep -o '"type":"[^"]*"' | head -1 | cut -d'"' -f4)
  echo "[INFO] Owner '${owner}' is type: ${owner_type}"

  echo "[INFO] Creating repository '${repo_name}' under '${owner}'..."
  local payload="{\"name\":\"${repo_name}\",\"private\":true,\"auto_init\":true}"
  local endpoint="/user/repos"
  [[ "$owner_type" == "Organization" ]] && endpoint="/orgs/${owner}/repos"

  local response
  response=$(gh_api POST "$endpoint" "$payload")
  local repo_url
  repo_url=$(echo "$response" | grep -o '"html_url":"[^"]*"' | head -1 | cut -d'"' -f4)

  if [[ -z "$repo_url" || "$repo_url" == "null" ]]; then
    echo "[ERROR] Failed to create repository"
    echo "$response" >&2
    exit 1
  fi
  echo "[SUCCESS] Repository created: ${repo_url}"

  if [[ -n "$collaborator" ]]; then
    echo "[INFO] Inviting '${collaborator}' with '${role}' role..."
    local inv_payload="{\"permission\":\"${role}\"}"
    gh_api PUT "/repos/${owner}/${repo_name}/collaborators/${collaborator}" "$inv_payload" > /dev/null
    echo "[SUCCESS] Collaborator '${collaborator}' invited with '${role}' role"
  fi

  echo "[RESULT] ${repo_url}"
}
main "$@"
