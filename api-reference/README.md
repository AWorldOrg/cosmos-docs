# API Reference

This folder contains the API reference material published to ApiDog. It is organized into two sections with independent publishing workflows.

## Structure

```
api-reference/
  .env                          # Shared credentials (gitignored)
  docs/                         # Markdown documentation
    publish.sh                  # Publishes markdown docs to ApiDog
    mapping.json                # Doc IDs and branch mapping
    en/
      01-getting-started.md
      02-authentication.md
      03-api-architecture.md
  schemas/                      # OpenAPI specifications
    import.sh                   # Imports OpenAPI schemas to ApiDog
    app.openapi.json
    dashboard.openapi.json
```

## Setup

Edit `.env` with your ApiDog credentials:

```bash
# Shared credentials
APIDOG_TOKEN=your-token-here
PROJECT_ID=your-project-id

# OpenAPI schema import settings
MODULE_ID_APP=your-app-module-id
MODULE_ID_DASHBOARD=your-dashboard-module-id
BRANCH_ID_SCHEMAS=your-schema-branch-id
```

**Where to find these values:**
- **APIDOG_TOKEN**: ApiDog Settings > API Access > Generate Token
- **PROJECT_ID**: The numeric ID in your ApiDog project URL
- **MODULE_ID_***: ApiDog project > API module tree > each module's ID
- **BRANCH_ID_SCHEMAS**: ApiDog project > branch selector > branch ID

Doc IDs and the documentation branch are configured separately in `docs/mapping.json`.

## Publishing markdown docs

```bash
cd docs

./publish.sh                        # Publish all 3 docs
./publish.sh --doc authentication   # Publish a single doc
./publish.sh --dry-run              # Test without publishing
```

API reference docs are **English-only** (no Italian branch).

## Importing OpenAPI schemas

```bash
cd schemas

./import.sh                     # Import both schemas
./import.sh --schema app        # Import only App API
./import.sh --schema dashboard  # Import only Dashboard API
./import.sh --dry-run           # Test without importing
```

The schemas are fetched by ApiDog from their GitHub raw URLs. Make sure the files are committed and pushed before running the import.
