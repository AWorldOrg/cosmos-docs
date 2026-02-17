# Publishing API Reference Documentation

This guide explains how to publish the API reference documentation (folder `02-api-overview`) to ApiDog.

## Overview

The API reference documentation uses **separate configuration files** from the product documentation:

| File | Purpose | Documentation Type |
|------|---------|-------------------|
| `.env` + `mapping.json` + `publish.sh` | Product docs (01-aworld-lab) | High-level product info |
| `.env.api` + `mapping-api.json` + `publish-api.sh` | API reference (02-api-overview) | Technical API documentation |

## Setup

### Step 1: Configure `.env.api`

Edit `.env.api` and replace the placeholders:

```bash
# Replace with your actual ApiDog API token
APIDOG_TOKEN=APS-your-actual-token-here

# Replace with your API reference project ID in ApiDog
PROJECT_ID=123456
```

**Where to find these values:**
- **APIDOG_TOKEN**: ApiDog Settings → API Access → Generate Token
- **PROJECT_ID**: ApiDog Project URL → The numeric ID in the URL

### Step 2: Configure `mapping-api.json`

Edit `mapping-api.json` and replace the placeholders:

```json
{
  "branches": {
    "en": "800258"  // Replace with your English branch ID
  },
  "docs": [
    {
      "doc_id": "1215381",  // Replace with actual doc ID for Getting Started
      "path": "02-api-overview/01-getting-started.md",
      "title": {
        "en": "Getting Started"
      }
    },
    {
      "doc_id": "1215379",  // Replace with actual doc ID for Authentication
      "path": "02-api-overview/02-authentication.md",
      "title": {
        "en": "Authentication"
      }
    },
    {
      "doc_id": "1215380",  // Replace with actual doc ID for API Architecture
      "path": "02-api-overview/03-api-architecture.md",
      "title": {
        "en": "API Architecture"
      }
    }
  ]
}
```

**Where to find these values:**
1. Go to your ApiDog project for API reference
2. Navigate to the documentation section
3. For each document, click edit and note the doc ID from the URL
4. Note the branch ID from the branch selector

**Important**: API reference docs are **English-only**, so no Italian branch is needed.

## Usage

### Publish All API Docs

```bash
./publish-api.sh
```

This publishes all three API reference documents:
- 01-getting-started.md
- 02-authentication.md
- 03-api-architecture.md

### Dry Run (Test Without Publishing)

```bash
./publish-api.sh --dry-run
```

This validates configuration and shows what would be published without actually sending to ApiDog.

### Publish Single Document

```bash
./publish-api.sh --doc authentication
```

This publishes only the authentication document (matches any doc path containing "authentication").

## Validation

The script validates configuration before publishing:

✅ **Checks performed:**
- `.env.api` file exists
- `APIDOG_TOKEN` is set and not a placeholder
- `PROJECT_ID` is set and not a placeholder
- `mapping-api.json` file exists
- Branch ID is not a placeholder
- Doc IDs are not placeholders
- All referenced files exist in `en/02-api-overview/`

❌ **Common errors:**
- `APIDOG_TOKEN is still a placeholder` → Edit `.env.api` with real token
- `PROJECT_ID is still a placeholder` → Edit `.env.api` with real project ID
- `Branch ID is still a placeholder` → Edit `mapping-api.json` with real branch ID
- `doc_id is still placeholder` → Edit `mapping-api.json` with real doc IDs
- `file not found` → Check that the file exists in `en/02-api-overview/`

## Output

Successful publish:
```
=== Apidog Publish (API Reference) ===
Project ID: 123456
Branch EN: 800258
Language: en (API docs are English-only)

✅ OK [en] Getting Started (ID: 1215381)
✅ OK [en] Authentication (ID: 1215379)
✅ OK [en] API Architecture (ID: 1215380)

=== Done: 3 ok, 0 failed ===
```

## Troubleshooting

### Authentication Failed

**Error**: `HTTP 401` or `HTTP 403`

**Solution**: Check that your `APIDOG_TOKEN` in `.env.api` is valid and has write permissions.

### Document Not Found

**Error**: `HTTP 404`

**Solution**: Verify that the `doc_id` in `mapping-api.json` matches the actual document ID in ApiDog.

### Wrong Project or Branch

**Error**: Document appears in wrong location

**Solution**:
- Verify `PROJECT_ID` in `.env.api`
- Verify branch ID in `mapping-api.json`
- Check ApiDog UI to confirm correct project and branch

## Comparison with Product Docs

| Aspect | Product Docs | API Reference |
|--------|--------------|---------------|
| **Folder** | `01-aworld-lab/` | `02-api-overview/` |
| **Languages** | English + Italian | English only |
| **Config** | `.env`, `mapping.json` | `.env.api`, `mapping-api.json` |
| **Script** | `./publish.sh` | `./publish-api.sh` |
| **Documents** | 5 docs | 3 docs |
| **Branches** | 2 (en + it) | 1 (en only) |

## Security

⚠️ **Important**: Both `.env` and `.env.api` contain sensitive tokens:

- **DO NOT** commit these files to Git
- Both files are in `.gitignore`
- Store tokens securely (e.g., password manager)
- Rotate tokens regularly
- Use separate tokens for production vs staging if possible

## Workflow

Typical workflow for updating API docs:

1. **Edit documentation**: Modify files in `en/02-api-overview/`
2. **Test locally**: Review changes in your markdown editor
3. **Dry run**: `./publish-api.sh --dry-run`
4. **Publish**: `./publish-api.sh`
5. **Verify**: Check ApiDog UI to confirm changes

## Next Steps

After setup:

1. ✅ Edit `.env.api` with real values
2. ✅ Edit `mapping-api.json` with real doc IDs and branch ID
3. ✅ Test with `./publish-api.sh --dry-run`
4. ✅ Publish with `./publish-api.sh`
5. ✅ Verify in ApiDog that docs appear correctly
