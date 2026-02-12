#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
MAPPING_FILE="$SCRIPT_DIR/mapping.json"

# Load .env
if [[ ! -f "$ENV_FILE" ]]; then
  echo "Error: .env file not found"
  exit 1
fi
source "$ENV_FILE"

if [[ -z "${APIDOG_TOKEN:-}" ]]; then
  echo "Error: APIDOG_TOKEN not set in .env"
  exit 1
fi

if [[ ! -f "$MAPPING_FILE" ]]; then
  echo "Error: mapping.json not found"
  exit 1
fi

# Apidog API config
BASE_URL="https://api.apidog.com/api/v1/doc"
PROJECT_ID="${PROJECT_ID:-820817}"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Parse arguments
DRY_RUN=false
SINGLE_DOC=""
LANG="all"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --doc) SINGLE_DOC="$2"; shift 2 ;;
    --lang) LANG="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# Validate --lang
if [[ "$LANG" != "en" && "$LANG" != "it" && "$LANG" != "all" ]]; then
  echo "Error: --lang must be en, it, or all"
  exit 1
fi

# Read branch IDs from mapping
BRANCH_EN=$(jq -r '.branches.en' "$MAPPING_FILE")
BRANCH_IT=$(jq -r '.branches.it' "$MAPPING_FILE")

# Build list of languages to publish
if [[ "$LANG" == "all" ]]; then
  LANGS=("en" "it")
else
  LANGS=("$LANG")
fi

echo "=== Apidog Publish ==="
echo "Languages: ${LANGS[*]}"
echo ""

TOTAL=$(jq '.docs | length' "$MAPPING_FILE")
SUCCESS=0
FAILED=0

for i in $(seq 0 $((TOTAL - 1))); do
  DOC_ID=$(jq -r ".docs[$i].doc_id" "$MAPPING_FILE")

  DOC_PATH=$(jq -r ".docs[$i].path" "$MAPPING_FILE")

  # If --doc is specified, skip non-matching entries
  if [[ -n "$SINGLE_DOC" && "$DOC_PATH" != *"$SINGLE_DOC"* ]]; then
    continue
  fi

  for CURRENT_LANG in "${LANGS[@]}"; do
    # Title for this language, fallback to EN
    TITLE=$(jq -r ".docs[$i].title.$CURRENT_LANG // .docs[$i].title.en" "$MAPPING_FILE")

    # Select branch ID
    if [[ "$CURRENT_LANG" == "en" ]]; then
      BRANCH_ID="$BRANCH_EN"
    else
      BRANCH_ID="$BRANCH_IT"
    fi

    FILE_PATH="$SCRIPT_DIR/$CURRENT_LANG/$DOC_PATH"
    LABEL="[$CURRENT_LANG] $TITLE"

    if [[ ! -f "$FILE_PATH" ]]; then
      echo -e "${RED}SKIP${NC} $LABEL — file not found: $CURRENT_LANG/$DOC_PATH"
      FAILED=$((FAILED + 1))
      continue
    fi

    CONTENT=$(cat "$FILE_PATH")

    if [[ "$DRY_RUN" == true ]]; then
      echo -e "${YELLOW}DRY-RUN${NC} $LABEL (ID: $DOC_ID, branch: $BRANCH_ID) ← $CURRENT_LANG/$DOC_PATH"
      continue
    fi

    # Build JSON payload
    PAYLOAD=$(jq -n \
      --arg name "$TITLE" \
      --arg content "$CONTENT" \
      '{name: $name, content: $content}')

    RESPONSE=$(curl -s -w "\n%{http_code}" \
      -X PUT "${BASE_URL}/${DOC_ID}?locale=en-US" \
      -H "Content-Type: application/json;charset=UTF-8" \
      -H "Authorization: Bearer ${APIDOG_TOKEN}" \
      -H "x-project-id: ${PROJECT_ID}" \
      -H "x-branch-id: ${BRANCH_ID}" \
      --data-raw "$PAYLOAD")

    HTTP_CODE=$(echo "$RESPONSE" | tail -1)
    BODY=$(echo "$RESPONSE" | sed '$d')
    API_SUCCESS=$(echo "$BODY" | jq -r '.success // false')

    if [[ "$HTTP_CODE" == "200" && "$API_SUCCESS" == "true" ]]; then
      echo -e "${GREEN}OK${NC} $LABEL (ID: $DOC_ID)"
      SUCCESS=$((SUCCESS + 1))
    else
      echo -e "${RED}FAIL${NC} $LABEL (ID: $DOC_ID) — HTTP $HTTP_CODE"
      echo "  Response: $BODY"
      FAILED=$((FAILED + 1))
    fi
  done
done

echo ""
echo "=== Done: $SUCCESS ok, $FAILED failed ==="
