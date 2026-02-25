#!/usr/bin/env bash
set -euo pipefail

# Import OpenAPI Schemas to ApiDog
# =================================
# Imports app.openapi.json and dashboard.openapi.json from GitHub
# into the ApiDog project as API specifications.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"

# Load .env
if [[ ! -f "$ENV_FILE" ]]; then
  echo "Error: .env file not found"
  echo "Please create .env with APIDOG_TOKEN, PROJECT_ID, MODULE_ID_*, and BRANCH_ID_SCHEMAS"
  exit 1
fi
source "$ENV_FILE"

# Validate required variables
for VAR in APIDOG_TOKEN_SCHEMAS PROJECT_ID MODULE_ID_APP MODULE_ID_DASHBOARD BRANCH_ID_SCHEMAS; do
  if [[ -z "${!VAR:-}" ]]; then
    echo "Error: $VAR not set in .env"
    exit 1
  fi
  if [[ "${!VAR}" == YOUR_* ]]; then
    echo "Error: $VAR is still a placeholder — update .env with actual value"
    exit 1
  fi
done

# Config
API_URL="https://api.apidog.com/v1/projects/${PROJECT_ID}/import-openapi?locale=en-US"
API_VERSION="2024-03-28"
GITHUB_BASE="https://raw.githubusercontent.com/AWorldOrg/cosmos-docs/main/api-reference/schemas"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Parse arguments
DRY_RUN=false
SINGLE_SCHEMA=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --schema) SINGLE_SCHEMA="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

echo "=== ApiDog OpenAPI Schema Import ==="
echo "Project ID: $PROJECT_ID"
echo ""

SUCCESS=0
FAILED=0

import_schema() {
  local name="$1"
  local file="$2"
  local module_id="$3"
  local url="${GITHUB_BASE}/${file}"

  if [[ -n "$SINGLE_SCHEMA" && "$name" != *"$SINGLE_SCHEMA"* ]]; then
    return
  fi

  if [[ "$DRY_RUN" == true ]]; then
    echo -e "${YELLOW}DRY-RUN${NC} $name (module: $module_id, branch: $BRANCH_ID_SCHEMAS)"
    echo "  URL: $url"
    return
  fi

  RESPONSE=$(curl -s -w "\n%{http_code}" \
    -X POST "$API_URL" \
    -H "X-Apidog-Api-Version: ${API_VERSION}" \
    -H "Authorization: Bearer ${APIDOG_TOKEN_SCHEMAS}" \
    -H "Content-Type: application/json" \
    --data-raw "{
      \"input\": {
        \"url\": \"${url}\"
      },
      \"options\": {
        \"moduleId\": ${module_id},
        \"targetBranchId\": ${BRANCH_ID_SCHEMAS},
        \"endpointOverwriteBehavior\": \"OVERWRITE_EXISTING\",
        \"schemaOverwriteBehavior\": \"OVERWRITE_EXISTING\",
        \"prependBasePath\": false
      }
    }")

  HTTP_CODE=$(echo "$RESPONSE" | tail -1)
  BODY=$(echo "$RESPONSE" | sed '$d')

  if [[ "$HTTP_CODE" == "200" ]]; then
    # Extract counters from response
    CREATED=$(echo "$BODY" | jq -r '.data.counters.endpointCreated // 0' 2>/dev/null || echo "0")
    UPDATED=$(echo "$BODY" | jq -r '.data.counters.endpointUpdated // 0' 2>/dev/null || echo "0")
    SCHEMAS=$(echo "$BODY" | jq -r '.data.counters.schemaUpdated // 0' 2>/dev/null || echo "0")
    echo -e "${GREEN}OK${NC} $name (module: $module_id) — endpoints: ${CREATED} created, ${UPDATED} updated | schemas: ${SCHEMAS} updated"
    SUCCESS=$((SUCCESS + 1))
  else
    echo -e "${RED}FAIL${NC} $name (module: $module_id) — HTTP $HTTP_CODE"
    echo "  Response: $BODY"
    FAILED=$((FAILED + 1))
  fi
}

import_schema "App API" "app.openapi.json" "$MODULE_ID_APP"
import_schema "Dashboard API" "dashboard.openapi.json" "$MODULE_ID_DASHBOARD"

echo ""
echo "=== Done: $SUCCESS ok, $FAILED failed ==="
