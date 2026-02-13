#!/usr/bin/env bash
###############################################################################
# github_add_user_to_repo.sh
# Adds a user to an existing repo with a specified role.
# Usage: ./github_add_user_to_repo.sh <owner> <repo_name> <username> [role]
# Role defaults to "push" (write). Options: pull, triage, push, maintain, admin
###############################################################################
set -euo pipefail
readonly API_BASE="${GITHUB_API_URL:-https://api.github.com}"

usage() { echo "Usage: $(basename "$0") <owner> <repo_name> <username> [role]"; exit 1; }
[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && usage
[[ $# -lt 3 ]] && usage
check_env() { [[ -z "${GITHUB_TOKEN:-}" ]] && echo "[ERROR] GITHUB_TOKEN not set" >&2 && exit 1; }

gh_api() {
  local method="$1" endpoint="$2" body="${3:-}"
  local -a args=(--silent --show-error -w "\n%{http_code}" -X "$method"
    -H "Accept: application/vnd.github+json" -H "Authorization: Bearer ${GITHUB_TOKEN}"
    -H "X-GitHub-Api-Version: 2022-11-28" "${API_BASE}${endpoint}")
  [[ -n "$body" ]] && args+=(-H "Content-Type: application/json" -d "$body")
  curl "${args[@]}"
}

main() {
  local owner="$1" repo_name="$2" username="$3" role="${4:-push}"
  check_env

  echo "[INFO] Verifying repository '${owner}/${repo_name}'..."
  local raw http_code
  raw=$(gh_api GET "/repos/${owner}/${repo_name}")
  http_code=$(echo "$raw" | tail -n1)
  [[ "$http_code" -ne 200 ]] && echo "[ERROR] Repository not found (HTTP ${http_code})" >&2 && exit 1
  echo "[INFO] Repository verified"

  echo "[INFO] Verifying user '${username}'..."
  raw=$(gh_api GET "/users/${username}")
  http_code=$(echo "$raw" | tail -n1)
  [[ "$http_code" -ne 200 ]] && echo "[ERROR] User not found (HTTP ${http_code})" >&2 && exit 1
  echo "[INFO] User verified"

  echo "[INFO] Adding '${username}' with '${role}' role to '${owner}/${repo_name}'..."
  local payload="{\"permission\":\"${role}\"}"
  raw=$(gh_api PUT "/repos/${owner}/${repo_name}/collaborators/${username}" "$payload")
  http_code=$(echo "$raw" | tail -n1)

  case "$http_code" in
    201) echo "[SUCCESS] Invitation sent to '${username}' with '${role}' access" ;;
    204) echo "[SUCCESS] User '${username}' permission set to '${role}'" ;;
    *) echo "[ERROR] Unexpected HTTP ${http_code}" >&2; exit 1 ;;
  esac
}
main "$@"
