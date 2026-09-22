# Users API

This document describes the API for retrieving the current user's profile.

## General information

- Local base URL: `http://localhost:3000/api/v1`
- Every endpoint in this module requires `Authorization: Bearer <accessToken>`.
- Date-time values in responses are ISO 8601 strings in UTC.

Successful response:

```json
{
  "statusCode": 200,
  "message": "User retrieved successfully",
  "data": {}
}
```

Error response:

```json
{
  "statusCode": 401,
  "errorCode": "ACCESS_TOKEN_EXPIRED",
  "message": "Access token has expired",
  "timestamp": "2026-09-22T10:00:00.000Z",
  "path": "/api/v1/users/me"
}
```

## Data type

```ts
interface User {
  id: number;
  email: string;
  createdAt: string; // ISO 8601
  updatedAt: string; // ISO 8601
}
```

## Get the current user

`GET /users/me`

This endpoint has no query parameters or request body.

```http
GET /api/v1/users/me
Authorization: Bearer <access-token>
```

`200 OK` response:

```json
{
  "statusCode": 200,
  "message": "User retrieved successfully",
  "data": {
    "id": 1,
    "email": "user@gmail.com",
    "createdAt": "2026-09-22T10:00:00.000Z",
    "updatedAt": "2026-09-22T10:00:00.000Z"
  }
}
```

Errors:

| HTTP | `errorCode` | Cause |
| --- | --- | --- |
| 401 | `ACCESS_TOKEN_INVALID` | Missing or invalid access token |
| 401 | `ACCESS_TOKEN_EXPIRED` | The access token has expired |
| 401 | `UNAUTHORIZED` | The user referenced by the token no longer exists |

The frontend can call this endpoint when the application starts to validate the session and retrieve the latest profile. If the access token has expired, refresh the token as described in `auth-api.md`, then retry this request.

