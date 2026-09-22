# Categories API

This document describes the APIs used to manage expense categories.

## General information

- Local base URL: `http://localhost:3000/api/v1`
- Every endpoint requires `Authorization: Bearer <accessToken>`.
- A user can access system default categories and custom categories created by that user.
- Default categories cannot be updated or deleted.
- A user cannot view, update, or delete another user's custom categories.

Successful response:

```json
{
  "statusCode": 200,
  "message": "Categories retrieved successfully",
  "data": []
}
```

Error response:

```json
{
  "statusCode": 409,
  "errorCode": "CATEGORY_ALREADY_EXISTS",
  "message": "Category already exists",
  "timestamp": "2026-09-22T10:00:00.000Z",
  "path": "/api/v1/categories"
}
```

## Data type

```ts
interface Category {
  id: number;
  name: string;
  isDefault: boolean;
  userId: number | null;
  createdAt: string; // ISO 8601
  updatedAt: string; // ISO 8601
}
```

- `isDefault: true` and `userId: null` identify a system category.
- `isDefault: false` and a non-null `userId` identify a user-owned custom category.

## List categories

`GET /categories`

Returns all system default categories and the current user's custom categories. Default categories appear first. Categories within each group are sorted by name in ascending order.

```http
GET /api/v1/categories
Authorization: Bearer <access-token>
```

`200 OK` response:

```json
{
  "statusCode": 200,
  "message": "Categories retrieved successfully",
  "data": [
    {
      "id": 1,
      "name": "Food",
      "isDefault": true,
      "userId": null,
      "createdAt": "2026-09-22T10:00:00.000Z",
      "updatedAt": "2026-09-22T10:00:00.000Z"
    },
    {
      "id": 9,
      "name": "Gym",
      "isDefault": false,
      "userId": 1,
      "createdAt": "2026-09-22T10:05:00.000Z",
      "updatedAt": "2026-09-22T10:05:00.000Z"
    }
  ]
}
```

## Create a custom category

`POST /categories`

Request body:

| Field | Type | Required | Rules |
| --- | --- | --- | --- |
| `name` | string | Yes | Must not contain only whitespace; maximum 100 characters |

```http
POST /api/v1/categories
Authorization: Bearer <access-token>
Content-Type: application/json

{
  "name": "Gym"
}
```

`201 Created` response:

```json
{
  "statusCode": 201,
  "message": "Category created successfully",
  "data": {
    "id": 9,
    "name": "Gym",
    "isDefault": false,
    "userId": 1,
    "createdAt": "2026-09-22T10:05:00.000Z",
    "updatedAt": "2026-09-22T10:05:00.000Z"
  }
}
```

The backend trims the name and collapses consecutive whitespace into a single space. Duplicate checks are case-insensitive and compare the name against both system categories and the current user's custom categories.

## Update a custom category

`PATCH /categories/:id`

Path parameter:

| Field | Type | Rules |
| --- | --- | --- |
| `id` | integer | Must be a valid integer |

Request body:

```json
{
  "name": "Fitness"
}
```

The `200 OK` response returns the updated `Category`:

```json
{
  "statusCode": 200,
  "message": "Category updated successfully",
  "data": {
    "id": 9,
    "name": "Fitness",
    "isDefault": false,
    "userId": 1,
    "createdAt": "2026-09-22T10:05:00.000Z",
    "updatedAt": "2026-09-22T10:10:00.000Z"
  }
}
```

The frontend should display the edit action only when `isDefault === false` and `userId` matches the current user's ID.

## Delete a custom category

`DELETE /categories/:id`

Only a custom category owned by the current user and not referenced by any expense can be deleted.

```http
DELETE /api/v1/categories/9
Authorization: Bearer <access-token>
```

`200 OK` response:

```json
{
  "statusCode": 200,
  "message": "Category deleted successfully",
  "data": null
}
```

## Module error codes

| HTTP | `errorCode` | Cause |
| --- | --- | --- |
| 400 | `VALIDATION_ERROR` | Invalid body or `id`, or an undeclared field in the body |
| 401 | `ACCESS_TOKEN_INVALID` | Missing or invalid access token |
| 401 | `ACCESS_TOKEN_EXPIRED` | The access token has expired |
| 403 | `CATEGORY_NOT_EDITABLE` | An attempt was made to update or delete a default category |
| 404 | `CATEGORY_NOT_FOUND` | The category does not exist or belongs to another user |
| 409 | `CATEGORY_ALREADY_EXISTS` | The name duplicates a system category or an existing custom category |
| 409 | `CATEGORY_IN_USE` | One or more expenses currently use the category |

