#!/usr/bin/env bash
###############################################################################
# github_remove_user_from_org_repos.sh
# Removes a user from every repo in an organisation.
# Usage: ./github_remove_user_from_org_repos.sh <owner> <username>
###############################################################################
set -euo pipefail
readonly API_BASE="${GITHUB_API_URL:-https://api.github.com}"
readonly PER_PAGE=100

usage() { echo "Usage: $(basename "$0") <owner> <username>"; exit 1; }
[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && usage
[[ $# -lt 2 ]] && usage
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
  local org="$1" username="$2"
  check_env

  echo "[INFO] Fetching all repositories for '${org}'..."
  local all_repos=() page=1
  while true; do
    local raw http_code body
    raw=$(gh_api GET "/orgs/${org}/repos?per_page=${PER_PAGE}&page=${page}")
    http_code=$(echo "$raw" | tail -n1)
    body=$(echo "$raw" | sed '$d')
    [[ "$http_code" -ne 200 ]] && echo "[ERROR] Failed to fetch repos (HTTP ${http_code})" >&2 && exit 1
    local count
    count=$(echo "$body" | grep -o '"full_name"' | wc -l | tr -d ' ')
    [[ "$count" -eq 0 ]] && break
    while IFS= read -r name; do all_repos+=("$name"); done < <(echo "$body" | grep -o '"full_name":"[^"]*"' | cut -d'"' -f4)
    [[ "$count" -lt "$PER_PAGE" ]] && break
    ((page++))
  done

  local total=${#all_repos[@]}
  echo "[INFO] Found ${total} repositories"

  local affected=0
  for repo in "${all_repos[@]}"; do
    echo "[INFO] Checking '${repo}'..."
    local raw http_code
    raw=$(gh_api DELETE "/repos/${repo}/collaborators/${username}")
    http_code=$(echo "$raw" | tail -n1)
    case "$http_code" in
      204) echo "[SUCCESS] Removed '${username}' from '${repo}'"; ((affected++)) ;;
      404) echo "[INFO] Not a collaborator on '${repo}'" ;;
      *) echo "[WARN] HTTP ${http_code} for '${repo}'" ;;
    esac
  done

  echo "[RESULT] Removed from ${affected} of ${total} repositories"
}
main "$@"
