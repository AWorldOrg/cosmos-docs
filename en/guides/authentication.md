# Authentication & Authorization

This guide explains how authentication and authorization work in the AWorld platform.

## Overview

AWorld uses AWS Cognito with a custom domain for authentication, implementing standard OAuth2 flows. The platform supports both user-centric authentication and machine-to-machine (M2M) authorization through client credentials.

## Authentication Methods

### User Authentication (OAuth2)

For user-centric applications, AWorld implements the standard OAuth2 authorization code flow:

1. **Authorization Request**: The client redirects the user to the Cognito authorization endpoint
2. **User Authentication**: The user authenticates with their credentials
3. **Authorization Code**: Upon successful authentication, the authorization server redirects back with an authorization code
4. **Token Exchange**: The client exchanges the authorization code for access and refresh tokens
5. **API Access**: The client uses the access token to make authenticated API requests

### Machine-to-Machine Authentication (Client Credentials)

For M2M interactions, AWorld supports the OAuth2 client credentials flow:

1. **Token Request**: The client makes a direct request to the token endpoint with client ID and secret
2. **Token Response**: The authorization server returns access tokens
3. **API Access**: The client uses the access token to make authenticated API requests

## Token Types

### Access Token

- Used to access protected resources and APIs
- JWT format containing claims about the authenticated user or client
- Short-lived (typically 1 hour)
- Must be included in API requests as a Bearer token in the Authorization header

### Refresh Token

- Used to obtain new access tokens when they expire
- Long-lived (typically 30 days)
- Should be securely stored by the client
- Cannot be used to access protected resources directly

### ID Token

- Contains user identity information
- JWT format
- Used by the client application to verify the user's identity
- Not intended for API authorization

## Authentication Endpoints

| Endpoint                                     | Description                                        |
| -------------------------------------------- | -------------------------------------------------- |
| `https://auth.aworld.cloud/oauth2/authorize` | Authorization endpoint for initiating OAuth2 flows |
| `https://auth.aworld.cloud/oauth2/token`     | Token endpoint for obtaining access tokens         |
| `https://auth.aworld.cloud/oauth2/userInfo`  | User info endpoint for obtaining user details      |

## User Contexts and Access Levels

### Principal (Platform-level User)

Principals have access across accounts and typically represent administrators or super-users.

### User (Workspace-level User)

Users are scoped to a specific workspace within an account, with permissions limited to their assigned workspace.

## Integrating with AWorld Authentication

### Web Applications

For web applications, we recommend using the authorization code flow with PKCE (Proof Key for Code Exchange):

```javascript
// Example authorization request
const authorizationUrl = new URL('https://auth.AWorld.example.com/oauth2/authorize');
authorizationUrl.searchParams.append('client_id', 'YOUR_CLIENT_ID');
authorizationUrl.searchParams.append('response_type', 'code');
authorizationUrl.searchParams.append('redirect_uri', 'YOUR_REDIRECT_URI');
authorizationUrl.searchParams.append('scope', 'openid profile email');
authorizationUrl.searchParams.append('state', 'YOUR_STATE_VALUE');
authorizationUrl.searchParams.append('code_challenge', 'YOUR_CODE_CHALLENGE');
authorizationUrl.searchParams.append('code_challenge_method', 'S256');

// Redirect user to authorization URL
window.location.href = authorizationUrl.toString();
```

### Mobile Applications

Mobile applications should also use the authorization code flow with PKCE, typically using a system browser or in-app browser tab.

### Server-side Applications

Server-side applications can use the client credentials flow to obtain access tokens without user interaction:

```javascript
/**
 * Minimal example of obtaining a token using OAuth2 client credentials flow
 */
async function getClientCredentialsToken() {
  // Configuration
  const tokenEndpoint = 'https://auth.aworld.cloud/oauth2/token';
  const clientId = 'YOUR_CLIENT_ID';
  const clientSecret = 'YOUR_CLIENT_SECRET';
  const scope = 'YOUR_SCOPES'; // Optional, space-separated

  try {
    // Create Basic Auth header
    const authHeader = Buffer.from(`${clientId}:${clientSecret}`).toString('base64');
    
    // Prepare request body
    const body = new URLSearchParams();
    body.append('grant_type', 'client_credentials');
    if (scope) body.append('scope', scope);
    
    // Make the request
    const response = await fetch(tokenEndpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': `Basic ${authHeader}`
      },
      body: body
    });
    
    // Handle the response
    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Request failed: ${response.status} ${errorText}`);
    }
    
    // Parse and return token data
    const tokenData = await response.json();
    return tokenData;
  } catch (error) {
    console.error('Token request failed:', error);
    throw error;
  }
}

// Example usage
getClientCredentialsToken()
  .then(token => {
    console.log(`Access Token: ${token.access_token}`);
    console.log(`Expires in: ${token.expires_in} seconds`);
    
    // Use this token for API requests
    // const apiResponse = await fetch('https://api.example.com/resource', {
    //   headers: { 'Authorization': `Bearer ${token.access_token}` }
    // });
  })
  .catch(error => console.error('Authentication failed:', error));
```

> **Note**: The correct token endpoint for AWorld is `https://auth.aworld.cloud/oauth2/token`

## Best Practices

1. **Never expose client secrets** in public-facing applications (use authorization code flow with PKCE instead)
2. **Always validate tokens** before trusting their content
3. **Store refresh tokens securely** to prevent unauthorized access
4. **Implement token renewal** to handle token expiration
5. **Use HTTPS** for all authentication-related requests
6. **Implement proper error handling** for authentication failures
7. **Limit scope requests** to only what your application needs
8. **Implement proper logout** to clean up sessions and tokens

## Common Issues and Troubleshooting

### Invalid Token

If you receive an "Invalid token" error, the token may have expired or been tampered with. Request a new access token using your refresh token.

### Invalid Grant

This typically occurs when trying to use an authorization code more than once or when using an expired refresh token.

### Unauthorized Client

This error indicates that the client doesn't have permission to use the requested grant type or scopes.

## Additional Resources

- [OAuth 2.0 Specification](https://oauth.net/2/)
- [AWS Cognito Documentation](https://docs.aws.amazon.com/cognito/latest/developerguide/what-is-amazon-cognito.html)
- [JWT.io](https://jwt.io/) - For debugging JSON Web Tokens
