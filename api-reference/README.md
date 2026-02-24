# Publishing API Reference Documentation

This guide explains how to publish the API reference documentation to ApiDog.

## Setup

### Step 1: Configure `.env`

Edit `.env` and replace the placeholders:

```bash
# Replace with your actual ApiDog API token
APIDOG_TOKEN=APS-your-actual-token-here

# Replace with your API reference project ID in ApiDog
PROJECT_ID=123456
```

**Where to find these values:**
- **APIDOG_TOKEN**: ApiDog Settings → API Access → Generate Token
- **PROJECT_ID**: ApiDog Project URL → The numeric ID in the URL

### Step 2: Configure `mapping.json`

Edit `mapping.json` and replace the placeholders:

```json
{
  "branches": {
    "en": "800258"
  },
  "docs": [
    {
      "doc_id": "1963860",
      "path": "01-getting-started.md",
      "title": {
        "en": "Getting Started"
      }
    },
    {
      "doc_id": "1960903",
      "path": "02-authentication.md",
      "title": {
        "en": "Authentication"
      }
    },
    {
      "doc_id": "1963861",
      "path": "03-api-architecture.md",
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
./publish.sh
```

This publishes all three API reference documents:
- 01-getting-started.md
- 02-authentication.md
- 03-api-architecture.md

### Dry Run (Test Without Publishing)

```bash
./publish.sh --dry-run
```

This validates configuration and shows what would be published without actually sending to ApiDog.

### Publish Single Document

```bash
./publish.sh --doc authentication
```

This publishes only the authentication document (matches any doc path containing "authentication").

## Validation

The script validates configuration before publishing:

**Checks performed:**
- `.env` file exists
- `APIDOG_TOKEN` is set and not a placeholder
- `PROJECT_ID` is set and not a placeholder
- `mapping.json` file exists
- Branch ID is not a placeholder
- Doc IDs are not placeholders
- All referenced files exist in `en/`

**Common errors:**
- `APIDOG_TOKEN is still a placeholder` → Edit `.env` with real token
- `PROJECT_ID is still a placeholder` → Edit `.env` with real project ID
- `Branch ID is still a placeholder` → Edit `mapping.json` with real branch ID
- `doc_id is still placeholder` → Edit `mapping.json` with real doc IDs
- `file not found` → Check that the file exists in `en/`

## Troubleshooting

### Authentication Failed

**Error**: `HTTP 401` or `HTTP 403`

**Solution**: Check that your `APIDOG_TOKEN` in `.env` is valid and has write permissions.

### Document Not Found

**Error**: `HTTP 404`

**Solution**: Verify that the `doc_id` in `mapping.json` matches the actual document ID in ApiDog.

### Wrong Project or Branch

**Error**: Document appears in wrong location

**Solution**:
- Verify `PROJECT_ID` in `.env`
- Verify branch ID in `mapping.json`
- Check ApiDog UI to confirm correct project and branch

## Security

**Important**: `.env` contains sensitive tokens:

- **DO NOT** commit this file to Git
- `.env` is in `.gitignore`
- Store tokens securely (e.g., password manager)
- Rotate tokens regularly

## Workflow

Typical workflow for updating API docs:

1. **Edit documentation**: Modify files in `en/`
2. **Test locally**: Review changes in your markdown editor
3. **Dry run**: `./publish.sh --dry-run`
4. **Publish**: `./publish.sh`
5. **Verify**: Check ApiDog UI to confirm changes
