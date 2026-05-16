#!/usr/bin/env bash
# codelinter-all.sh
# Runs HarmonyOS codelinter across all projects in projects/
# Usage: bash tools/codelinter-all.sh [project-name]
# Example: bash tools/codelinter-all.sh inspection-photo-app

set -euo pipefail

WORKSPACE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECTS_DIR="${WORKSPACE_ROOT}/projects"
PASS=0
FAIL=0
SKIP=0

lint_project() {
  local project_dir="$1"
  local project_name
  project_name=$(basename "$project_dir")

  # Skip if no hvigorw (project not yet initialized by DevEco Studio)
  if [[ ! -f "${project_dir}/hvigorw" && ! -f "${project_dir}/hvigorw.bat" ]]; then
    echo "  [SKIP] ${project_name} — hvigorw not found (run DevEco Studio first)"
    ((SKIP++))
    return
  fi

  echo "  [LINT] ${project_name}..."

  # Determine script name based on OS
  local hvigorw
  if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    hvigorw="./hvigorw.bat"
  else
    hvigorw="./hvigorw"
    chmod +x "$hvigorw" 2>/dev/null || true
  fi

  # Run codelinter
  local output
  if output=$(cd "$project_dir" && $hvigorw codelinter --no-daemon 2>&1); then
    echo "  [PASS] ${project_name}"
    ((PASS++))
  else
    echo "  [FAIL] ${project_name}"
    echo "$output" | grep -E "ERROR|WARNING|error|warning" | head -20 || true
    ((FAIL++))
  fi
}

main() {
  echo "========================================"
  echo " HarmonyOS Workspace Linter"
  echo " Workspace: ${WORKSPACE_ROOT}"
  echo "========================================"
  echo ""

  if [[ $# -gt 0 ]]; then
    # Lint specific project
    local project_dir="${PROJECTS_DIR}/$1"
    if [[ ! -d "$project_dir" ]]; then
      echo "ERROR: Project not found: $project_dir" >&2
      exit 1
    fi
    lint_project "$project_dir"
  else
    # Lint all projects
    for project_dir in "${PROJECTS_DIR}"/*/; do
      if [[ -d "$project_dir" ]]; then
        lint_project "$project_dir"
      fi
    done
  fi

  echo ""
  echo "========================================"
  echo " Results: ${PASS} passed, ${FAIL} failed, ${SKIP} skipped"
  echo "========================================"

  if [[ $FAIL -gt 0 ]]; then
    exit 1
  fi
}

main "$@"
