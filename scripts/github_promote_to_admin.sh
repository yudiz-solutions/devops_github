#!/usr/bin/env bash
###############################################################################
# github_promote_to_admin.sh
# Promotes/changes a user's role on a specific repository.
# Usage: ./github_promote_to_admin.sh <owner> <repo_name> <username> [role]
# Role defaults to "admin". Options: pull, triage, push, maintain, admin
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
  local owner="$1" repo_name="$2" username="$3" role="${4:-admin}"
  check_env

  echo "[INFO] Verifying repository '${owner}/${repo_name}'..."
  local raw http_code
  raw=$(gh_api GET "/repos/${owner}/${repo_name}")
  http_code=$(echo "$raw" | tail -n1)
  [[ "$http_code" -ne 200 ]] && echo "[ERROR] Repository not found (HTTP ${http_code})" >&2 && exit 1

  echo "[INFO] Setting '${username}' to '${role}' on '${owner}/${repo_name}'..."
  local payload="{\"permission\":\"${role}\"}"
  raw=$(gh_api PUT "/repos/${owner}/${repo_name}/collaborators/${username}" "$payload")
  http_code=$(echo "$raw" | tail -n1)

  case "$http_code" in
    200|201) echo "[SUCCESS] User '${username}' now has '${role}' access on ${owner}/${repo_name}" ;;
    204) echo "[SUCCESS] Permission already set" ;;
    404) echo "[ERROR] Repository or user not found" >&2; exit 1 ;;
    422) echo "[ERROR] Validation error" >&2; exit 1 ;;
    *) echo "[ERROR] HTTP ${http_code}" >&2; exit 1 ;;
  esac
}
main "$@"
