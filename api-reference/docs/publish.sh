#!/usr/bin/env bash
set -euo pipefail

# Publish Script for API Reference Documentation
# ===============================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"
MAPPING_FILE="$SCRIPT_DIR/mapping.json"

# Load .env
if [[ ! -f "$ENV_FILE" ]]; then
  echo "Error: .env file not found"
  echo "Please create .env with APIDOG_TOKEN and PROJECT_ID"
  exit 1
fi
source "$ENV_FILE"

if [[ -z "${APIDOG_TOKEN:-}" ]]; then
  echo "Error: APIDOG_TOKEN not set in .env"
  exit 1
fi

if [[ "$APIDOG_TOKEN" == "YOUR_APIDOG_TOKEN_HERE" ]]; then
  echo "Error: APIDOG_TOKEN in .env is still a placeholder"
  echo "Please replace YOUR_APIDOG_TOKEN_HERE with actual token"
  exit 1
fi

if [[ -z "${PROJECT_ID:-}" ]]; then
  echo "Error: PROJECT_ID not set in .env"
  exit 1
fi

if [[ "$PROJECT_ID" == "YOUR_PROJECT_ID_HERE" ]]; then
  echo "Error: PROJECT_ID in .env is still a placeholder"
  echo "Please replace YOUR_PROJECT_ID_HERE with actual project ID"
  exit 1
fi

if [[ ! -f "$MAPPING_FILE" ]]; then
  echo "Error: mapping.json not found"
  exit 1
fi

# Apidog API config
BASE_URL="https://api.apidog.com/api/v1/doc"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Parse arguments
DRY_RUN=false
SINGLE_DOC=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --doc) SINGLE_DOC="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# Read branch ID from mapping (only EN for API reference)
BRANCH_EN=$(jq -r '.branches.en' "$MAPPING_FILE")

if [[ "$BRANCH_EN" == "YOUR_ENGLISH_BRANCH_ID_HERE" ]]; then
  echo "Error: Branch ID in mapping.json is still a placeholder"
  echo "Please replace YOUR_ENGLISH_BRANCH_ID_HERE with actual branch ID"
  exit 1
fi

echo "=== Apidog Publish (API Reference) ==="
echo "Project ID: $PROJECT_ID"
echo "Branch EN: $BRANCH_EN"
echo "Language: en (API docs are English-only)"
echo ""

TOTAL=$(jq '.docs | length' "$MAPPING_FILE")
SUCCESS=0
FAILED=0

for i in $(seq 0 $((TOTAL - 1))); do
  DOC_ID=$(jq -r ".docs[$i].doc_id" "$MAPPING_FILE")

  # Check if doc_id is still placeholder
  if [[ "$DOC_ID" =~ YOUR_DOC_ID ]]; then
    DOC_PATH=$(jq -r ".docs[$i].path" "$MAPPING_FILE")
    echo -e "${YELLOW}SKIP${NC} $DOC_PATH — doc_id is still placeholder: $DOC_ID"
    FAILED=$((FAILED + 1))
    continue
  fi

  DOC_PATH=$(jq -r ".docs[$i].path" "$MAPPING_FILE")

  # If --doc is specified, skip non-matching entries
  if [[ -n "$SINGLE_DOC" && "$DOC_PATH" != *"$SINGLE_DOC"* ]]; then
    continue
  fi

  TITLE=$(jq -r ".docs[$i].title.en" "$MAPPING_FILE")
  FILE_PATH="$SCRIPT_DIR/en/$DOC_PATH"
  LABEL="[en] $TITLE"

  if [[ ! -f "$FILE_PATH" ]]; then
    echo -e "${RED}SKIP${NC} $LABEL — file not found: en/$DOC_PATH"
    FAILED=$((FAILED + 1))
    continue
  fi

  CONTENT=$(cat "$FILE_PATH")

  if [[ "$DRY_RUN" == true ]]; then
    echo -e "${YELLOW}DRY-RUN${NC} $LABEL (ID: $DOC_ID, branch: $BRANCH_EN) ← en/$DOC_PATH"
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

echo ""
echo "=== Done: $SUCCESS ok, $FAILED failed ==="
