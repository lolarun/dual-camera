#!/usr/bin/env bash
# fetch-harmony-docs.sh
# Clones openharmony/docs via git sparse-checkout and copies the directory
# tree into docs/harmonyos-api/, preserving the original structure exactly
# as it appears in the openharmony/docs repository.
#
# Usage:
#   bash tools/fetch-harmony-docs.sh        # full refresh
#
# Source: https://github.com/openharmony/docs
# Path:   zh-cn/application-dev/

set -euo pipefail

WORKSPACE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${WORKSPACE_ROOT}/docs/harmonyos-api"
TMP_DIR="/tmp/oh-docs-$$"
REPO="https://github.com/openharmony/docs.git"

# Directories to fetch from zh-cn/application-dev/
# Mirrors the original structure — do not rename.
DIRS=(
  "zh-cn/application-dev/media"
  "zh-cn/application-dev/database"
  "zh-cn/application-dev/device"
  "zh-cn/application-dev/file-management"
  "zh-cn/application-dev/graphics"
  "zh-cn/application-dev/security"
  "zh-cn/application-dev/ui"
  "zh-cn/application-dev/windowmanager"
  "zh-cn/application-dev/network"
  "zh-cn/application-dev/connectivity"
  "zh-cn/application-dev/application-models"
  "zh-cn/application-dev/quick-start"
  "zh-cn/application-dev/arkts-utils"
  "zh-cn/application-dev/performance"
  "zh-cn/application-dev/dfx"
)

log() { echo "  $*"; }

echo "======================================"
echo " HarmonyOS Docs Fetcher"
echo " Source: openharmony/docs (GitHub)"
echo "======================================"

if ! command -v git &>/dev/null; then
  echo "ERROR: git not found." >&2; exit 1
fi

log "Cloning (sparse, depth=1, no blobs)..."
git clone \
  --depth=1 \
  --filter=blob:none \
  --sparse \
  "$REPO" \
  "$TMP_DIR" 2>&1 | grep -v "^remote:" || true

log "Fetching directory trees..."
cd "$TMP_DIR" && git sparse-checkout set "${DIRS[@]}"

SRC="${TMP_DIR}/zh-cn/application-dev"

log "Copying to ${DEST} (preserving original structure)..."
mkdir -p "$DEST"
for dir in media database device file-management graphics security ui \
           windowmanager network connectivity application-models \
           quick-start arkts-utils performance dfx; do
  [ -d "${SRC}/${dir}" ] && cp -r "${SRC}/${dir}" "${DEST}/${dir}"
done

rm -rf "$TMP_DIR"
log "Temp clone removed."

echo ""
echo "======================================"
echo " Done — directory counts:"
echo "======================================"
total=0
for d in "${DEST}"/*/; do
  count=$(find "$d" -name "*.md" 2>/dev/null | wc -l)
  total=$((total + count))
  printf "  %-25s %d files\n" "$(basename "$d")" "$count"
done
echo "  ─────────────────────────────────"
printf "  %-25s %d files\n" "TOTAL" "$total"
echo ""
echo "Index for inspection-photo-app:"
echo "  projects/inspection-photo-app/docs/api-index.md"
