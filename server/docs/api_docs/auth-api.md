# Authentication API

This document describes the `Auth` module APIs used by the frontend for registration, login, token refresh, and logout.

## General information

- Local base URL: `http://localhost:3000/api/v1`
- Content type: `application/json`
- Registration, login, and token refresh do not require an access token.
- Logout requires the `Authorization: Bearer <accessToken>` header.
- Access tokens and refresh tokens serve different purposes. Do not send a refresh token as a Bearer token.
- Default lifetimes are `1 day` for access tokens and `7 days` for refresh tokens. The backend can override these values through environment variables.
- `register`, `login`, and `refresh` are limited to 10 requests per minute. Other endpoints use the default limit of 100 requests per minute.

## Response format

Successful response:

```json
{
  "statusCode": 200,
  "message": "Login successful",
  "data": {}
}
```

Error response:

```json
{
  "statusCode": 400,
  "errorCode": "VALIDATION_ERROR",
  "message": "Invalid request data",
  "errors": [
    {
      "field": "email",
      "message": "email must be an email"
    }
  ],
  "timestamp": "2026-09-22T10:00:00.000Z",
  "path": "/api/v1/auth/login"
}
```

The `errors` property is included only when the backend provides field-level error details.

## Shared types

```ts
interface PublicAuthUser {
  id: number;
  email: string;
  createdAt: string; // ISO 8601
}

interface TokenPair {
  accessToken: string;
  refreshToken: string;
}

interface AuthResult extends TokenPair {
  user: PublicAuthUser;
}
```

## Register

`POST /auth/register`

Creates a user account and immediately returns a token pair.

Request body:

| Field | Type | Required | Rules |
| --- | --- | --- | --- |
| `email` | string | Yes | Valid email address, maximum 255 characters |
| `password` | string | Yes | Between 8 and 72 characters |

Example:

```http
POST /api/v1/auth/register
Content-Type: application/json

{
  "email": "user@gmail.com",
  "password": "User123456@"
}
```

`201 Created` response:

```json
{
  "statusCode": 201,
  "message": "User registered successfully",
  "data": {
    "user": {
      "id": 1,
      "email": "user@gmail.com",
      "createdAt": "2026-09-22T10:00:00.000Z"
    },
    "accessToken": "<jwt-access-token>",
    "refreshToken": "<jwt-refresh-token>"
  }
}
```

Errors:

| HTTP | `errorCode` | Cause |
| --- | --- | --- |
| 400 | `VALIDATION_ERROR` | Invalid email or password, or an undeclared field in the body |
| 409 | `EMAIL_ALREADY_EXISTS` | The email address is already registered |
| 429 | `VALIDATION_ERROR` | Request rate limit exceeded |

The backend trims the email address and converts it to lowercase before storing it.

## Login

`POST /auth/login`

The request body uses the same validation rules as registration.

```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "email": "user@gmail.com",
  "password": "User123456@"
}
```

`200 OK` response:

```json
{
  "statusCode": 200,
  "message": "Login successful",
  "data": {
    "user": {
      "id": 1,
      "email": "user@gmail.com",
      "createdAt": "2026-09-22T10:00:00.000Z"
    },
    "accessToken": "<jwt-access-token>",
    "refreshToken": "<jwt-refresh-token>"
  }
}
```

Errors:

| HTTP | `errorCode` | Cause |
| --- | --- | --- |
| 400 | `VALIDATION_ERROR` | Invalid request body |
| 401 | `INVALID_CREDENTIALS` | The email does not exist or the password is incorrect |
| 429 | `VALIDATION_ERROR` | Request rate limit exceeded |

## Refresh tokens

`POST /auth/refresh`

Send the refresh token in the request body. This endpoint does not require an access token.

```http
POST /api/v1/auth/refresh
Content-Type: application/json

{
  "refreshToken": "<current-refresh-token>"
}
```

`200 OK` response:

```json
{
  "statusCode": 200,
  "message": "Token refreshed successfully",
  "data": {
    "accessToken": "<new-access-token>",
    "refreshToken": "<new-refresh-token>"
  }
}
```

The backend uses refresh-token rotation. The old refresh token is revoked immediately after a successful refresh. The frontend must replace both stored tokens with the new pair and must never reuse the old refresh token.

Errors:

| HTTP | `errorCode` | Cause |
| --- | --- | --- |
| 400 | `VALIDATION_ERROR` | Missing token or value is not a valid JWT string |
| 401 | `REFRESH_TOKEN_INVALID` | Invalid signature, token not found, or token belongs to another user |
| 401 | `REFRESH_TOKEN_EXPIRED` | The refresh token has expired |
| 401 | `REFRESH_TOKEN_REVOKED` | The refresh token has already been used or revoked |
| 429 | `VALIDATION_ERROR` | Request rate limit exceeded |

## Logout

`POST /auth/logout`

Revokes one active refresh token. The request requires both an access token and a refresh token belonging to the same user.

```http
POST /api/v1/auth/logout
Authorization: Bearer <access-token>
Content-Type: application/json

{
  "refreshToken": "<current-refresh-token>"
}
```

`200 OK` response:

```json
{
  "statusCode": 200,
  "message": "Logout successful",
  "data": null
}
```

Errors:

| HTTP | `errorCode` | Cause |
| --- | --- | --- |
| 400 | `VALIDATION_ERROR` | Invalid request body |
| 401 | `ACCESS_TOKEN_INVALID` | Missing or invalid access token |
| 401 | `ACCESS_TOKEN_EXPIRED` | The access token has expired |
| 401 | `REFRESH_TOKEN_INVALID` | Invalid refresh token or token belongs to another user |
| 401 | `REFRESH_TOKEN_REVOKED` | The refresh token has already been revoked |

After a successful logout, the frontend should remove the access token, refresh token, and local session data.

## Recommended frontend flow

1. Store the `accessToken` and `refreshToken` securely after registration or login.
2. Attach `Authorization: Bearer <accessToken>` to every authenticated API request.
3. When an API returns `ACCESS_TOKEN_EXPIRED`, call `/auth/refresh` once while other failed requests wait.
4. If refresh succeeds, replace both stored tokens and retry the original request.
5. If refresh returns a 401 error, clear the session and redirect the user to the login screen.

