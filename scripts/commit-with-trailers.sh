#!/usr/bin/env bash
# ============================================================================
# commit-with-trailers.sh — ai-handover v4.0 Git Trailers Protocol
# ============================================================================
# Creates git commits with standard ai-handover trailers for decision
# traceability across multi-agent sessions.
#
# Usage:
#   ./commit-with-trailers.sh \
#       --message "feat: implement retry logic" \
#       --handover-id "20260625_143022_add-retry" \
#       --coding-agent "coder-milo" \
#       --model "gpt-4o" \
#       [--constraint "no-external-deps"] \
#       [--constraint "max-3-retries"] \
#       [--rejected-alternatives "circuit-breaker"] \
#       [--agent-directive "scope-creep:avoid"] \
#       [--verification "npm run lint:pass"] \
#       [--confidence "high"]
#
# Options:
#   -m, --message            Commit message (required)
#   -i, --handover-id        Handover-Id value (required)
#   -c, --coding-agent       Coding-Agent value (required)
#   -M, --model              Model value (required)
#   -C, --constraint         Constraint value (repeatable)
#   -r, --rejected-alternatives  Rejected-Alternatives value
#   -d, --agent-directive    Agent-Directive value
#   -v, --verification       Verification value (repeatable)
#   -f, --confidence         Confidence value (low/medium/high)
#       --help               Show this help and exit
#
# Examples:
#   ./commit-with-trailers.sh \
#       --message "refactor: extract auth middleware" \
#       --handover-id "20260625_102030_refactor-auth" \
#       --coding-agent "coder-zeta" \
#       --model "claude-sonnet-4" \
#       --constraint "backward-compat" \
#       --verification "pytest:pass" \
#       --confidence "high"
# ============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Help
# ---------------------------------------------------------------------------
show_help() {
  sed -n '3,/^$/p' "$0" | sed 's/^# \?//'
  exit 0
}

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
MESSAGE=""
HANDOVER_ID=""
CODING_AGENT=""
MODEL=""
CONSTRAINTS=()
REJECTED_ALTERNATIVES=""
AGENT_DIRECTIVE=""
VERIFICATIONS=()
CONFIDENCE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --help) show_help ;;
    -m|--message) MESSAGE="$2"; shift 2 ;;
    -i|--handover-id) HANDOVER_ID="$2"; shift 2 ;;
    -c|--coding-agent) CODING_AGENT="$2"; shift 2 ;;
    -M|--model) MODEL="$2"; shift 2 ;;
    -C|--constraint) CONSTRAINTS+=("$2"); shift 2 ;;
    -r|--rejected-alternatives) REJECTED_ALTERNATIVES="$2"; shift 2 ;;
    -d|--agent-directive) AGENT_DIRECTIVE="$2"; shift 2 ;;
    -v|--verification) VERIFICATIONS+=("$2"); shift 2 ;;
    -f|--confidence) CONFIDENCE="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; show_help; exit 1 ;;
  esac
done

# ---------------------------------------------------------------------------
# Validate required
# ---------------------------------------------------------------------------
if [ -z "$HANDOVER_ID" ]; then
  echo "ERROR: --handover-id is required" >&2
  exit 1
fi

if [ -z "$MESSAGE" ]; then
  echo "ERROR: --message is required" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Build commit body with trailers (heredoc)
# ---------------------------------------------------------------------------
TRAILERS="Handover-Id: $HANDOVER_ID"

if [ -n "$CODING_AGENT" ]; then
  TRAILERS="$TRAILERS"$'\n'"Coding-Agent: $CODING_AGENT"
fi

if [ -n "$MODEL" ]; then
  TRAILERS="$TRAILERS"$'\n'"Model: $MODEL"
fi

for c in "${CONSTRAINTS[@]}"; do
  TRAILERS="$TRAILERS"$'\n'"Constraint: $c"
done

if [ -n "$REJECTED_ALTERNATIVES" ]; then
  TRAILERS="$TRAILERS"$'\n'"Rejected-Alternatives: $REJECTED_ALTERNATIVES"
fi

if [ -n "$AGENT_DIRECTIVE" ]; then
  TRAILERS="$TRAILERS"$'\n'"Agent-Directive: $AGENT_DIRECTIVE"
fi

for v in "${VERIFICATIONS[@]}"; do
  TRAILERS="$TRAILERS"$'\n'"Verification: $v"
done

if [ -n "$CONFIDENCE" ]; then
  TRAILERS="$TRAILERS"$'\n'"Confidence: $CONFIDENCE"
fi

# ---------------------------------------------------------------------------
# Create commit with heredoc body
# ---------------------------------------------------------------------------
git commit -m "$MESSAGE" -m "$TRAILERS"
