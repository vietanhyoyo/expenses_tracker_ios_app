# Expenses API

This document describes the APIs used to create, retrieve, filter, update, and delete expenses.

## General information

- Local base URL: `http://localhost:3000/api/v1`
- Every endpoint requires `Authorization: Bearer <accessToken>`.
- Users can access only their own expenses.
- `categoryId` must reference either a system default category or a custom category owned by the current user.
- Date-time values in responses are ISO 8601 strings.
- The `amount` field in JSON responses is a decimal string because the database uses the `Decimal` type. To avoid rounding errors, the frontend should keep it as a string or use a decimal/currency type for calculations.

Successful response:

```json
{
  "statusCode": 200,
  "message": "Expense retrieved successfully",
  "data": {}
}
```

Error response:

```json
{
  "statusCode": 404,
  "errorCode": "EXPENSE_NOT_FOUND",
  "message": "Expense not found",
  "timestamp": "2026-09-22T10:00:00.000Z",
  "path": "/api/v1/expenses/99"
}
```

## Data types

```ts
interface ExpenseCategory {
  id: number;
  name: string;
  isDefault: boolean;
}

interface Expense {
  id: number;
  userId: number;
  categoryId: number;
  title: string;
  amount: string; // Decimal serialized as a string
  expenseDate: string; // ISO 8601
  location: string | null;
  notes: string | null;
  createdAt: string; // ISO 8601
  updatedAt: string; // ISO 8601
  category: ExpenseCategory;
}

interface PaginatedExpenses {
  items: Expense[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
}
```

## Create an expense

`POST /expenses`

Request body:

| Field | Type | Required | Rules |
| --- | --- | --- | --- |
| `title` | string | Yes | Must not contain only whitespace; maximum 150 characters |
| `amount` | number | Yes | From `0.01` to `9999999999999.99`, with no more than 2 decimal places |
| `expenseDate` | string | Yes | ISO 8601 date or date-time, for example `2026-09-22` |
| `categoryId` | integer | Yes | Integer greater than or equal to 1; category must be accessible |
| `location` | string | No | Maximum 255 characters |
| `notes` | string | No | Maximum 2,000 characters |

```http
POST /api/v1/expenses
Authorization: Bearer <access-token>
Content-Type: application/json

{
  "title": "Lunch",
  "amount": 120000,
  "expenseDate": "2026-09-22",
  "categoryId": 1,
  "location": "Can Tho",
  "notes": "Lunch with friends"
}
```

`201 Created` response:

```json
{
  "statusCode": 201,
  "message": "Expense created successfully",
  "data": {
    "id": 1,
    "userId": 1,
    "categoryId": 1,
    "title": "Lunch",
    "amount": "120000",
    "expenseDate": "2026-09-22T00:00:00.000Z",
    "location": "Can Tho",
    "notes": "Lunch with friends",
    "createdAt": "2026-09-22T10:00:00.000Z",
    "updatedAt": "2026-09-22T10:00:00.000Z",
    "category": {
      "id": 1,
      "name": "Food",
      "isDefault": true
    }
  }
}
```

The backend trims `title`, `location`, and `notes`. If `location` or `notes` is omitted or contains only whitespace, its stored value is `null`.

## List expenses

`GET /expenses`

Query parameters:

| Field | Type | Default | Rules |
| --- | --- | --- | --- |
| `page` | integer | `1` | Greater than or equal to 1 |
| `limit` | integer | `20` | From 1 to 100 |
| `categoryId` | integer | Not set | Greater than or equal to 1 |
| `from` | string | Not set | ISO 8601 date/date-time; filters by `expenseDate >= from` |
| `to` | string | Not set | ISO 8601 date/date-time; filters by `expenseDate <= to` |
| `sortBy` | string | `expenseDate` | `expenseDate`, `amount`, or `createdAt` |
| `sortOrder` | string | `desc` | `asc` or `desc` |

Example:

```http
GET /api/v1/expenses?page=1&limit=20&categoryId=1&from=2026-09-01&to=2026-09-30&sortBy=expenseDate&sortOrder=desc
Authorization: Bearer <access-token>
```

When `to` uses the `YYYY-MM-DD` format, the backend includes records through `23:59:59.999Z` on that date. `from` must be earlier than or equal to `to`.

`200 OK` response:

```json
{
  "statusCode": 200,
  "message": "Expenses retrieved successfully",
  "data": {
    "items": [
      {
        "id": 1,
        "userId": 1,
        "categoryId": 1,
        "title": "Lunch",
        "amount": "120000",
        "expenseDate": "2026-09-22T00:00:00.000Z",
        "location": "Can Tho",
        "notes": "Lunch with friends",
        "createdAt": "2026-09-22T10:00:00.000Z",
        "updatedAt": "2026-09-22T10:00:00.000Z",
        "category": {
          "id": 1,
          "name": "Food",
          "isDefault": true
        }
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 1,
      "totalPages": 1
    }
  }
}
```

When no records match, `items` is `[]`, while `total` and `totalPages` are both `0`.

## Get an expense

`GET /expenses/:id`

```http
GET /api/v1/expenses/1
Authorization: Bearer <access-token>
```

The `200 OK` response contains one `Expense` object in `data` and uses the message `Expense retrieved successfully`.

The backend returns `EXPENSE_NOT_FOUND` both when the ID does not exist and when the expense belongs to another user. The frontend does not need to, and should not attempt to, distinguish these cases.

## Update an expense

`PATCH /expenses/:id`

Every request field is optional. Any field included in the request must satisfy the same validation rules as the create endpoint.

```http
PATCH /api/v1/expenses/1
Authorization: Bearer <access-token>
Content-Type: application/json

{
  "title": "Dinner",
  "amount": 180000,
  "categoryId": 2,
  "notes": ""
}
```

The `200 OK` response returns the complete updated `Expense` and uses the message `Expense updated successfully`.

To clear `location` or `notes`, send an empty string (`""`). The backend stores it as `null`. Do not send `null`, because the DTO accepts only strings.

## Delete an expense

`DELETE /expenses/:id`

```http
DELETE /api/v1/expenses/1
Authorization: Bearer <access-token>
```

`200 OK` response:

```json
{
  "statusCode": 200,
  "message": "Expense deleted successfully",
  "data": null
}
```

## Module error codes

| HTTP | `errorCode` | Cause |
| --- | --- | --- |
| 400 | `VALIDATION_ERROR` | Invalid body, path parameter, or query; `from > to`; or an undeclared field was sent |
| 401 | `ACCESS_TOKEN_INVALID` | Missing or invalid access token |
| 401 | `ACCESS_TOKEN_EXPIRED` | The access token has expired |
| 404 | `CATEGORY_NOT_FOUND` | `categoryId` does not exist or is outside the user's accessible categories |
| 404 | `EXPENSE_NOT_FOUND` | The expense does not exist or belongs to another user |

Example date-range error:

```json
{
  "statusCode": 400,
  "errorCode": "VALIDATION_ERROR",
  "message": "Invalid date range",
  "errors": [
    {
      "field": "from",
      "message": "from must be before or equal to to"
    }
  ],
  "timestamp": "2026-09-22T10:00:00.000Z",
  "path": "/api/v1/expenses?from=2026-10-01&to=2026-09-01"
}
```

