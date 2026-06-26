#!/usr/bin/env bash
# ============================================================================
# validate.sh — ai-handover v4.1 Directory & Integrity Validator
# ============================================================================
# Checks integrity of an AI交接记录/ directory with 8 validation checks:
#   1. 执行记录完整性 — 索引.md exists and each referenced folder exists
#   2. YAML frontmatter 必填字段 — Required fields present
#   3. prev_handover_id 链完整性 — Chain links are valid (except "init")
#   4. git trailers 存在性 — Last commit has Handover-Id, Coding-Agent, Model
#   5. Lane 状态跳转合法性 — State transitions follow legal rules
#   6. 文件锁冲突检测 — No stale locks in .ai-handover/locks/
#   7. hot.md 更新检测 — hot.md has been modified recently
#   8. next_action 格式 — next_action contains @agent reference
#
# Usage:
#   ./validate.sh                                   # validate default dir
#   ./validate.sh /path/to/AI交接记录                # custom path
#   ./validate.sh --verbose                          # detailed output
#   ./validate.sh --fix                              # auto-fix minor issues
#   ./validate.sh --help                             # this help
#
# Exit code: 0 = all pass, 1 = failures
# ============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
VERBOSE=false
FIX=false
TARGET_DIR=""
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Guard: require bash =4.0 for associative arrays
if ! declare -A _ &>/dev/null 2>&1; then
    echo "ERROR: bash =4.0 required. Current version: $BASH_VERSION" >&2
    echo "  macOS: brew install bash" >&2
    exit 1
fi

# Legal lane transitions (status -> allowed next statuses)
declare -A LEGAL_TRANSITIONS
LEGAL_TRANSITIONS=(
  ["idle"]="in-progress"
  ["in-progress"]="needs-review blocked"
  ["needs-review"]="ready-for-merge changes-requested blocked"
  ["changes-requested"]="in-progress blocked cancelled"
  ["ready-for-merge"]="resolved blocked"
  ["resolved"]="idle"
  ["blocked"]="in-progress cancelled"
  ["cancelled"]=""
)

REQUIRED_FRONTMATTER=(
  "handover_id"
  "prev_handover_id"
  "agent_id"
  "agent_role"
  "coding_agent"
  "model"
  "status"
  "branch"
  "files_modified"
  "verification"
  "next_action"
  "lock_files"
)

# Stale lock timeout in minutes
LOCK_TIMEOUT_MINUTES=30

# ---------------------------------------------------------------------------
# Help
# ---------------------------------------------------------------------------
show_help() {
  sed -n '3,/^$/p' "$0" | sed 's/^# \?//'
  exit 0
}

# ---------------------------------------------------------------------------
# Utilities
# ---------------------------------------------------------------------------
log()    { echo "  $*"; }
info()   { echo "[INFO] $*"; }
warn()   { echo "[WARN] $*"; }
fail()   { echo "[FAIL] $*"; failures=$((failures + 1)); }
pass()   { echo "[PASS] $*"; }

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
while [ $# -gt 0 ]; do
  case "$1" in
    --help) show_help ;;
    --verbose) VERBOSE=true; shift ;;
    --fix) FIX=true; shift ;;
    -*)
      echo "Unknown option: $1" >&2
      show_help
      ;;
    *)
      TARGET_DIR="$1"
      shift
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Determine target directory
# ---------------------------------------------------------------------------
if [ -z "$TARGET_DIR" ]; then
  for candidate in "$PROJECT_ROOT/AI交接记录"; do
    if [ -d "$candidate" ]; then
      TARGET_DIR="$candidate"
      break
    fi
  done
fi

if [ -z "$TARGET_DIR" ] || [ ! -d "$TARGET_DIR" ]; then
  echo "ERROR: AI交接记录/ directory not found at or relative to $PROJECT_ROOT" >&2
  echo "Usage: $0 [--verbose] [--fix] [path/to/AI交接记录]" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Counters
# ---------------------------------------------------------------------------
failures=0

echo "============================================"
echo " ai-handover v4.1 — Validate"
echo " Target: $TARGET_DIR"
echo " Fix:    $FIX"
echo "============================================"
echo ""

# ===========================================================================
# Check 1: 执行记录完整性 — 索引.md & referenced folders
# ===========================================================================
$VERBOSE && log "--- Check 1: 执行记录完整性 ---"

INDEX_FILE=""
if [ -f "$TARGET_DIR/索引.md" ]; then
  INDEX_FILE="$TARGET_DIR/索引.md"
  pass "Check 1: 索引.md exists"
elif [ -f "$TARGET_DIR/index.md" ]; then
  INDEX_FILE="$TARGET_DIR/index.md"
  pass "Check 1: index.md exists (fallback)"
else
  fail "Check 1: 索引.md not found in $TARGET_DIR"
fi

REFERENCED_FOLDERS=""
if [ -n "$INDEX_FILE" ]; then
  LINE_COUNT=$(wc -l < "$INDEX_FILE" 2>/dev/null || echo 0)
  if [ "$LINE_COUNT" -gt 0 ]; then
    $VERBOSE && pass "Check 1: 索引.md has $LINE_COUNT lines"
  else
    warn "Check 1: 索引.md is empty"
  fi

  # Extract referenced handover folder names
  REFERENCED_FOLDERS=$(grep -oE '(^|[^a-zA-Z0-9_])[0-9]{8}_[0-9]{6}_[^/ )]+' "$INDEX_FILE" 2>/dev/null || true)

  MISSING_FOLDERS=()
  for folder in $REFERENCED_FOLDERS; do
    if [ -d "$TARGET_DIR/$folder" ]; then
      $VERBOSE && pass "Check 1: Folder '$folder' exists"
    else
      fail "Check 1: Referenced folder missing — 找不到 \"$folder\""
      MISSING_FOLDERS+=("$folder")
    fi
  done

  if [ ${#MISSING_FOLDERS[@]} -eq 0 ] && [ -n "$REFERENCED_FOLDERS" ]; then
    pass "Check 1: All referenced handover folders exist"
  fi
fi

# Discover actual handover folders for later checks
ACTUAL_FOLDERS=()
while IFS= read -r -d '' d; do
  name=$(basename "$d")
  ACTUAL_FOLDERS+=("$name")
done < <(find "$TARGET_DIR" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)

# Fix: rebuild index from actual folders
if [ "$FIX" = true ] && [ ! -f "$INDEX_FILE" ]; then
  INDEX_FILE="$TARGET_DIR/索引.md"
  : > "$INDEX_FILE"
  for folder in "${ACTUAL_FOLDERS[@]}"; do
    echo "$folder" >> "$INDEX_FILE"
  done
  info "Check 1: Rebuilt 索引.md from ${#ACTUAL_FOLDERS[@]} handover folders"
  pass "Check 1: 索引.md created (--fix)"
fi

# ===========================================================================
# Check 2: YAML frontmatter 必填字段
# ===========================================================================
$VERBOSE && log "--- Check 2: YAML frontmatter validation ---"

ALL_FRONTMATTER_OK=true
declare -A HANDOVER_STATUS_MAP
declare -A HANDOVER_PREV_MAP
declare -A HANDOVER_NEXTACTION_MAP

for folder in "${ACTUAL_FOLDERS[@]}"; do
  HANDOVER_DIR="$TARGET_DIR/$folder"
  EXEC_FILE="$HANDOVER_DIR/执行记录.md"
  [ ! -f "$EXEC_FILE" ] && EXEC_FILE="$HANDOVER_DIR/execution-record.md"
  [ ! -f "$EXEC_FILE" ] && continue

  FRONTMATTER=$(sed -n '/^---$/,/^---$/p' "$EXEC_FILE" 2>/dev/null || true)
  if [ -z "$FRONTMATTER" ]; then
    fail "Check 2: $folder — no YAML frontmatter"
    ALL_FRONTMATTER_OK=false
    continue
  fi

  HANDOVER_ID_VAL=$(echo "$FRONTMATTER" | sed -n 's/^handover_id:[[:space:]]*//p' | tr -d ' ')
  HANDOVER_STATUS_MAP["$folder"]=$(echo "$FRONTMATTER" | sed -n 's/^status:[[:space:]]*//p' | tr -d ' ')
  HANDOVER_PREV_MAP["$folder"]=$(echo "$FRONTMATTER" | sed -n 's/^prev_handover_id:[[:space:]]*//p' | tr -d ' ')
  HANDOVER_NEXTACTION_MAP["$folder"]=$(echo "$FRONTMATTER" | sed -n 's/^next_action:[[:space:]]*//p')

  for field in "${REQUIRED_FRONTMATTER[@]}"; do
    if echo "$FRONTMATTER" | grep -qE "^${field}:"; then
      $VERBOSE && pass "Check 2: $folder — field '$field' present"
    else
      fail "Check 2: $folder — required field '$field' missing in frontmatter"
      ALL_FRONTMATTER_OK=false
    fi
  done
done

if [ "$ALL_FRONTMATTER_OK" = true ]; then
  pass "Check 2: YAML frontmatter fields complete in all handover records"
fi

# ===========================================================================
# Check 3: prev_handover_id 链完整性
# ===========================================================================
$VERBOSE && log "--- Check 3: prev_handover_id chain integrity ---"

CHAIN_OK=true
# Build lookup of all handover_ids from ACTUAL_FOLDERS
declare -A KNOWN_HANDOVER_IDS
for folder in "${ACTUAL_FOLDERS[@]}"; do
  EXEC_FILE="$TARGET_DIR/$folder/执行记录.md"
  [ ! -f "$EXEC_FILE" ] && EXEC_FILE="$TARGET_DIR/$folder/execution-record.md"
  [ ! -f "$EXEC_FILE" ] && continue
  FM=$(sed -n '/^---$/,/^---$/p' "$EXEC_FILE" 2>/dev/null || true)
  HID=$(echo "$FM" | sed -n 's/^handover_id:[[:space:]]*//p' | tr -d ' ')
  [ -n "$HID" ] && KNOWN_HANDOVER_IDS["$HID"]="$folder"
done

for folder in "${ACTUAL_FOLDERS[@]}"; do
  PREV_ID="${HANDOVER_PREV_MAP[$folder]:-}"
  [ -z "$PREV_ID" ] && continue
  [ "$PREV_ID" = "init" ] && continue

  if [ -n "${KNOWN_HANDOVER_IDS[$PREV_ID]:-}" ]; then
    $VERBOSE && pass "Check 3: $folder -> prev=$PREV_ID (found)"
  else
    fail "Check 3: prev_handover_id 链断裂 — 找不到 \"$PREV_ID\" (from $folder)"
    CHAIN_OK=false
  fi
done

if [ "$CHAIN_OK" = true ]; then
  pass "Check 3: prev_handover_id chain is complete"
fi

# ===========================================================================
# Check 4: git trailers 存在性
# ===========================================================================
$VERBOSE && log "--- Check 4: git trailers ---"

if git -C "$PROJECT_ROOT" rev-parse --git-dir > /dev/null 2>&1; then
  TRAILERS=$(git -C "$PROJECT_ROOT" log --format="%(trailers)" -1 2>/dev/null || true)
  if [ -n "$TRAILERS" ]; then
    TRAILERS_OK=true
    for trailer in "Handover-Id" "Coding-Agent" "Model"; do
      if echo "$TRAILERS" | grep -qE "^${trailer}:"; then
        $VERBOSE && pass "Check 4: git trailer '$trailer' found"
      else
        fail "Check 4: git trailer '$trailer' missing from last commit"
        TRAILERS_OK=false
      fi
    done
    if [ "$TRAILERS_OK" = true ]; then
      pass "Check 4: Required git trailers (Handover-Id, Coding-Agent, Model) present"
    fi
  else
    fail "Check 4: No git trailers found in last commit"
  fi
else
  warn "Check 4: Not a git repository, skipping trailer check"
fi

# ===========================================================================
# Check 5: Lane 状态跳转合法性
# ===========================================================================
$VERBOSE && log "--- Check 5: Lane status transitions ---"

SORTED_FOLDERS=()
while IFS= read -r -d '' d; do
  SORTED_FOLDERS+=("$(basename "$d")")
done < <(find "$TARGET_DIR" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null | sort)

TRANSITIONS_OK=true
PREV_STATUS=""
for folder in "${SORTED_FOLDERS[@]}"; do
  CURR_STATUS="${HANDOVER_STATUS_MAP[$folder]:-}"
  [ -z "$CURR_STATUS" ] && continue

  if [ -n "$PREV_STATUS" ]; then
    ALLOWED="${LEGAL_TRANSITIONS[$PREV_STATUS]:-}"
    if [ -n "$ALLOWED" ]; then
      if echo "$ALLOWED" | grep -qw "$CURR_STATUS"; then
        $VERBOSE && pass "Check 5: $folder — $PREV_STATUS → $CURR_STATUS (legal)"
      else
        fail "Check 5: $folder — illegal transition $PREV_STATUS → $CURR_STATUS (allowed: $ALLOWED)"
        TRANSITIONS_OK=false
      fi
    fi
  fi
  [ -n "$CURR_STATUS" ] && PREV_STATUS="$CURR_STATUS"
done

if [ "$TRANSITIONS_OK" = true ]; then
  pass "Check 5: All lane status transitions are legal"
fi

# ===========================================================================
# Check 6: 文件锁冲突检测
# ===========================================================================
$VERBOSE && log "--- Check 6: File lock conflict detection ---"

LOCK_DIR="$PROJECT_ROOT/.ai-handover/locks"
STALE_LOCKS=0
if [ -d "$LOCK_DIR" ]; then
  NOW_EPOCH=$(date +%s 2>/dev/null || echo 0)
  while IFS= read -r -d '' lockfile; do
    LOCK_NAME=$(basename "$lockfile")
    # Check for heartbeat file
    HEARTBEAT_FILE="$lockfile.heartbeat"
    LOCK_MTIME=$(stat -c %Y "$lockfile" 2>/dev/null || stat -f %m "$lockfile" 2>/dev/null || echo 0)
    HB_MTIME=$LOCK_MTIME
    if [ -f "$HEARTBEAT_FILE" ]; then
      HB_MTIME=$(stat -c %Y "$HEARTBEAT_FILE" 2>/dev/null || stat -f %m "$HEARTBEAT_FILE" 2>/dev/null || echo "$LOCK_MTIME")
    fi
    if [ "$NOW_EPOCH" -gt 0 ] && [ "$HB_MTIME" -gt 0 ]; then
      AGE_MINUTES=$(( (NOW_EPOCH - HB_MTIME) / 60 ))
      if [ "$AGE_MINUTES" -gt "$LOCK_TIMEOUT_MINUTES" ]; then
        fail "Check 6: Stale lock detected — \"$LOCK_NAME\" (${AGE_MINUTES}m old, >${LOCK_TIMEOUT_MINUTES}m timeout)"
        STALE_LOCKS=$((STALE_LOCKS + 1))
      else
        $VERBOSE && pass "Check 6: Lock '$LOCK_NAME' is active (${AGE_MINUTES}m old)"
      fi
    fi
  done < <(find "$LOCK_DIR" -type f -name '*.lock' -print0 2>/dev/null)
else
  $VERBOSE && pass "Check 6: No lock directory, skipping"
fi

if [ "$STALE_LOCKS" -eq 0 ]; then
  pass "Check 6: No stale file locks detected"
fi

# ===========================================================================
# Check 7: hot.md 更新检测
# ===========================================================================
$VERBOSE && log "--- Check 7: hot.md update detection ---"

# Look for hot.md in common locations
HOT_MD=""
for candidate in "$PROJECT_ROOT/hot.md" "$TARGET_DIR/../hot.md" "$PROJECT_ROOT/wiki/hot.md"; do
  if [ -f "$candidate" ]; then
    HOT_MD="$candidate"
    break
  fi
done

if [ -n "$HOT_MD" ] && git -C "$PROJECT_ROOT" rev-parse --git-dir > /dev/null 2>&1; then
  HOT_MTIME=$(stat -c %Y "$HOT_MD" 2>/dev/null || stat -f %m "$HOT_MD" 2>/dev/null || echo 0)
  LAST_COMMIT_TIME=$(git -C "$PROJECT_ROOT" log -1 --format=%ct 2>/dev/null || echo 0)
  if [ "$HOT_MTIME" -gt 0 ] && [ "$LAST_COMMIT_TIME" -gt 0 ]; then
    if [ "$HOT_MTIME" -gt "$LAST_COMMIT_TIME" ]; then
      pass "Check 7: hot.md has been modified since last commit"
    else
      fail "Check 7: hot.md has NOT been modified since last commit (may need update)"
    fi
  else
    warn "Check 7: Could not determine modification times for hot.md"
  fi
elif [ -z "$HOT_MD" ]; then
  $VERBOSE && warn "Check 7: hot.md not found, skipping"
else
  warn "Check 7: Not a git repository, skipping hot.md check"
fi

# ===========================================================================
# Check 8: next_action 格式 (must contain @agent reference)
# ===========================================================================
$VERBOSE && log "--- Check 8: next_action format ---"

NEXT_ACTION_OK=true
for folder in "${ACTUAL_FOLDERS[@]}"; do
  NA="${HANDOVER_NEXTACTION_MAP[$folder]:-}"
  [ -z "$NA" ] && continue
  # Strip leading/trailing whitespace from value
  NA_VALUE=$(echo "$NA" | sed 's/^next_action:[[:space:]]*//')
  if echo "$NA_VALUE" | grep -qE '@[a-zA-Z_][a-zA-Z0-9_]*'; then
    $VERBOSE && pass "Check 8: $folder — next_action contains @agent reference"
  else
    fail "Check 8: $folder — next_action missing @agent reference (got: \"$NA_VALUE\")"
    NEXT_ACTION_OK=false
  fi
done

if [ "$NEXT_ACTION_OK" = true ]; then
  pass "Check 8: All next_action fields contain @agent references"
fi

# ===========================================================================
# Summary
# ===========================================================================
echo ""
echo "============================================"
echo " Summary"
echo "============================================"
echo " Failures: $failures"
echo ""

if [ "$failures" -eq 0 ]; then
  echo "RESULT: ALL CHECKS PASSED"
  exit 0
else
  echo "RESULT: $failures FAILURE(S) DETECTED"
  exit 1
fi
