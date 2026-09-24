# Budgets API

All endpoints require `Authorization: Bearer <accessToken>` and are scoped to the authenticated user.

Budgets are monthly limits for expense categories. The server stores the month normalized to the first day of that month at UTC midnight.

## Budget shape

```ts
interface Budget {
  id: number;
  userId: number;
  categoryId: number;
  amount: string;
  month: string;
  category: {
    userId: number | null;
    isDefault: boolean;
  };
  createdAt: string;
  updatedAt: string;
}
```

## List budgets

`GET /api/v1/budgets`

Returns all budgets belonging to the authenticated user, newest month first.

## Create a budget

`POST /api/v1/budgets`

```json
{
  "categoryId": 1,
  "amount": 500000,
  "month": "2026-09-01"
}
```

The category must be an accessible expense category. A user can have only one budget for a category in a month.

## Update a budget

`PATCH /api/v1/budgets/:id`

Any of `categoryId`, `amount`, and `month` can be updated. The same expense-category/month uniqueness rule applies.

## Delete a budget

`DELETE /api/v1/budgets/:id`

Only the owner can delete the budget.

## Error codes

| HTTP | `errorCode` | Cause |
| --- | --- | --- |
| 400 | `VALIDATION_ERROR` | Invalid category, amount, or month |
| 401 | `UNAUTHORIZED` | Missing or invalid access token |
| 404 | `BUDGET_NOT_FOUND` | Budget does not exist or belongs to another user |
| 404 | `CATEGORY_NOT_FOUND` | Category is missing, inaccessible, or not an expense category |
| 409 | `BUDGET_ALREADY_EXISTS` | A budget already exists for the category and month |
