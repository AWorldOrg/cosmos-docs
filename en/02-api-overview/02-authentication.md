AWorld Lab uses AWS Cognito with multi-tenant architecture. Each workspace has its own Cognito app client with isolated credentials.

**Auth Domain**: `https://auth.aworld.cloud`

**API Domain**: `https://api.eu-west-1.aworld.cloud`

> **Note**: The API domain will migrate to `https://api.aworld.cloud` on March 1, 2026. Both domains will work during the transition period.

## Authentication Methods

### 1. EMAIL_OTP (Passwordless)

Primary authentication method for end users. Sends a one-time password via email.

#### Step 1: Initiate OTP Request

```javascript
// Generate SECRET_HASH (required for Cognito clients with secret)
async function computeSecretHash(email, clientId, clientSecret) {
  const message = email + clientId;
  const encoder = new TextEncoder();
  const keyData = encoder.encode(clientSecret);
  const messageData = encoder.encode(message);

  const key = await crypto.subtle.importKey(
    'raw',
    keyData,
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );

  const signature = await crypto.subtle.sign('HMAC', key, messageData);
  const hashArray = Array.from(new Uint8Array(signature));
  const hashHex = hashArray.map(b => String.fromCharCode(b)).join('');
  return btoa(hashHex);
}

// Initiate EMAIL_OTP flow
async function initiateEmailOTP(email, clientId, clientSecret, region) {
  const secretHash = await computeSecretHash(email, clientId, clientSecret);

  const response = await fetch(`https://cognito-idp.${region}.amazonaws.com/`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-amz-json-1.1',
      'X-Amz-Target': 'AWSCognitoIdentityProviderService.InitiateAuth'
    },
    body: JSON.stringify({
      ClientId: clientId,
      AuthFlow: 'USER_AUTH',
      AuthParameters: {
        USERNAME: email,
        SECRET_HASH: secretHash,
        PREFERRED_CHALLENGE: 'EMAIL_OTP'
      }
    })
  });

  const data = await response.json();
  return data.Session; // Save this for step 2
}
```

**Important**: Store the returned `Session` token. It's required for OTP verification and expires after 3 minutes.

#### Step 2: Verify OTP Code

```javascript
async function verifyEmailOTP(email, otpCode, session, clientId, clientSecret, region) {
  const secretHash = await computeSecretHash(email, clientId, clientSecret);

  const response = await fetch(`https://cognito-idp.${region}.amazonaws.com/`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-amz-json-1.1',
      'X-Amz-Target': 'AWSCognitoIdentityProviderService.RespondToAuthChallenge'
    },
    body: JSON.stringify({
      ClientId: clientId,
      ChallengeName: 'EMAIL_OTP',
      Session: session,
      ChallengeResponses: {
        EMAIL_OTP_CODE: otpCode,
        USERNAME: email,
        SECRET_HASH: secretHash
      }
    })
  });

  const data = await response.json();
  const { AccessToken, IdToken, RefreshToken } = data.AuthenticationResult;

  return { AccessToken, IdToken, RefreshToken };
}
```

### 2. Machine-to-Machine (Client Credentials)

For server-to-server API calls without user interaction.

```javascript
async function getM2MToken(clientId, clientSecret) {
  const authHeader = btoa(`${clientId}:${clientSecret}`);

  const response = await fetch('https://auth.aworld.cloud/oauth2/token', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Authorization': `Basic ${authHeader}`
    },
    body: new URLSearchParams({
      grant_type: 'client_credentials',
      scope: 'app/read dashboard/write' // Example scopes
    })
  });

  const { access_token, expires_in } = await response.json();
  return access_token;
}
```

**User Impersonation**: M2M tokens can impersonate users by including `x-user-id` header in API calls:

```javascript
const response = await fetch('https://api.eu-west-1.aworld.cloud/app/v1/missions', {
  headers: {
    'Authorization': `Bearer ${m2mAccessToken}`,
    'x-user-id': userId // Impersonate this user
  }
});
```

## JWT Token Structure

### Access Token Claims

| Claim | Type | Required | Description |
|-------|------|----------|-------------|
| `sub` | string | ✓ | Cognito user ID |
| `workspaceId` | string | ✓ | Workspace ID (multi-tenant isolation) |
| `accountId` | string | ✓ | Account ID |
| `userId` | string | ✓ | User ID |
| `context` | string | ✓ | API context: `"dashboard"` \| `"app"` |
| `platform` | string | ✓ | `"web"` \| `"mobile"` \| `"m2m"` |
| `role` | string | ✓ | User role (e.g., `"admin"`, `"editor"`, `"viewer"`) |
| `lang` | string | - | ISO 639-1 language code (default: `"en"`) |
| `timezone` | string | - | IANA timezone (default: `"UTC"`) |
| `exp` | number | ✓ | Expiration timestamp (Unix seconds) |
| `iat` | number | ✓ | Issued at timestamp (Unix seconds) |

**TTL**: 1 hour

### ID Token Claims

Contains user profile information:

| Claim | Type | Description |
|-------|------|-------------|
| `sub` | string | Same as access token |
| `email` | string | User email address |
| `email_verified` | boolean | Email verification status |
| `name` | string | Full name |
| `given_name` | string | First name |
| `family_name` | string | Last name |
| `picture` | string | Avatar URL |
| `exp` | number | Expiration timestamp |

**TTL**: 1 hour

### Refresh Token

- Opaque token (not JWT)
- Used to obtain new access and ID tokens
- **TTL**: 30 days
- Does NOT change when refreshed

## Token Refresh

Access tokens expire after 1 hour. Use the refresh token to obtain new tokens without re-authentication.

```javascript
async function refreshAccessToken(refreshToken, clientId, clientSecret, region) {
  // Note: username can be extracted from the current access token before it expires
  const secretHash = await computeSecretHash(username, clientId, clientSecret);

  const response = await fetch(`https://cognito-idp.${region}.amazonaws.com/`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-amz-json-1.1',
      'X-Amz-Target': 'AWSCognitoIdentityProviderService.InitiateAuth'
    },
    body: JSON.stringify({
      AuthFlow: 'REFRESH_TOKEN_AUTH',
      ClientId: clientId,
      AuthParameters: {
        REFRESH_TOKEN: refreshToken,
        SECRET_HASH: secretHash
      }
    })
  });

  const data = await response.json();
  const { AccessToken, IdToken } = data.AuthenticationResult;

  // Note: Cognito does NOT return a new refresh token
  // Continue using the existing refresh token
  return { AccessToken, IdToken, RefreshToken: refreshToken };
}
```

**Important**:
- Cognito does NOT issue a new refresh token during refresh flow
- The original refresh token remains valid until its 30-day expiration
- When refresh token expires, user must re-authenticate

## Using Tokens in API Calls

### Authorization Header

```javascript
const response = await fetch('https://api.aworld.cloud/app/v1/missions', {
  headers: {
    'Authorization': `Bearer ${accessToken}`
  }
});
```

### Cookie-Based Authentication (Web Apps)

Store tokens in HTTP-only cookies for security:

```javascript
// Server-side: Set cookies after authentication
document.cookie = `auth.accessToken=${accessToken}; HttpOnly; Secure; SameSite=Lax; Max-Age=3600`;
document.cookie = `auth.idToken=${idToken}; HttpOnly; Secure; SameSite=Lax; Max-Age=3600`;
document.cookie = `auth.refreshToken=${refreshToken}; HttpOnly; Secure; SameSite=Lax; Max-Age=2592000`;
```

**Security**: HTTP-only cookies prevent JavaScript access, protecting against XSS attacks.

## API Context and Required Claims

Different API contexts require different token claims:

| API Context | Base URL | Required Claims | Use Case |
|-------------|----------|-----------------|----------|
| **Dashboard** | `/dashboard/v1/*` | `userId`, `workspaceId` | Content creation & configuration |
| **App** | `/app/v1/*` | `userId`, `workspaceId` | End-user interactions |

**Validation**: APIs validate that tokens contain the required claims for their context. Missing claims result in 403 Forbidden.

## Multi-Tenant Security

### Workspace ID Validation

Every API request validates that:
1. Token contains valid `workspaceId` claim
2. Requested resources belong to that workspace
3. User has permission to access those resources

**Critical**: `workspaceId` in token must match the workspace being accessed. Cross-workspace access is blocked at the API gateway level.

### Tenant Isolation

- Each workspace has isolated Cognito credentials
- User pools are separate per workspace
- Tokens are scoped to a single workspace
- Database queries automatically filter by `workspaceId`

## Best Practices

1. **Store tokens securely**: Use HTTP-only cookies for web apps, secure storage for mobile
2. **Validate workspaceId**: Always verify token's `workspaceId` matches the requested workspace
3. **Implement token refresh**: Handle token expiration gracefully without forcing re-login
4. **Never expose client secrets**: Keep secrets server-side only
5. **Use HTTPS**: All authentication requests must use HTTPS in production
6. **Implement proper logout**: Clear all tokens and terminate Cognito sessions
7. **Handle token expiration**: Check `exp` claim and refresh proactively

## Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `NotAuthorizedException` | Invalid credentials or expired token | Re-authenticate or refresh token |
| `CodeMismatchException` | Wrong OTP code | Verify user entered correct code |
| `ExpiredCodeException` | OTP or session expired | Request new OTP |
| `InvalidParameterException` | Missing or invalid SECRET_HASH | Verify SECRET_HASH calculation |
| `UserNotFoundException` | Email not registered | User must sign up first |

## Token Validation Example

```javascript
function isTokenExpired(token) {
  try {
    const payload = JSON.parse(atob(token.split('.')[1]));
    return payload.exp * 1000 < Date.now();
  } catch {
    return true;
  }
}

async function getValidAccessToken() {
  let accessToken = getStoredAccessToken();

  if (isTokenExpired(accessToken)) {
    const refreshToken = getStoredRefreshToken();
    const newTokens = await refreshAccessToken(refreshToken);
    accessToken = newTokens.AccessToken;
    storeTokens(newTokens);
  }

  return accessToken;
}
```

## Endpoint Reference

- **Auth Domain**: `https://auth.aworld.cloud`
- **API Domain**: `https://api.eu-west-1.aworld.cloud` (migrates to `https://api.aworld.cloud` on March 1, 2026)
- **Cognito Region**: `eu-west-1` (Ireland)
- **Cognito IDP**: `https://cognito-idp.eu-west-1.amazonaws.com/`
- **Token Endpoint**: `https://auth.aworld.cloud/oauth2/token`
