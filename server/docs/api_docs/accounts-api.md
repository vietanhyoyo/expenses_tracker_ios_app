# Accounts API

All endpoints require `Authorization: Bearer <accessToken>` and are scoped to the authenticated user.

## Account type

```ts
type AccountType = 'cash' | 'ewallet' | 'bank';
```

The first `GET /accounts` call creates the three default accounts when missing:

- `cash` — Tiền mặt
- `ewallet` — Ví điện tử
- `bank` — Ngân hàng

## List accounts

`GET /api/v1/accounts`

```json
{
  "statusCode": 200,
  "message": "Accounts retrieved successfully",
  "data": [
    {
      "id": 1,
      "userId": 1,
      "name": "Tiền mặt",
      "type": "cash",
      "initialBalance": "0",
      "isDefault": true,
      "createdAt": "2026-09-23T03:03:18.453Z",
      "updatedAt": "2026-09-23T03:03:18.453Z"
    }
  ]
}
```

## Create a custom account

`POST /api/v1/accounts`

```json
{
  "name": "Ví MoMo",
  "type": "ewallet",
  "initialBalance": 500000
}
```

`name` is required, `type` must be `cash`, `ewallet`, or `bank`, and `initialBalance` defaults to `0`.

## Update an account

`PATCH /api/v1/accounts/:id`

```json
{
  "name": "Ví MoMo chính",
  "initialBalance": 750000
}
```

## Delete an account

`DELETE /api/v1/accounts/:id`

Default accounts cannot be deleted. Custom accounts can be deleted by their owner.

## Error codes

| HTTP | `errorCode` | Cause |
| --- | --- | --- |
| 400 | `VALIDATION_ERROR` | Invalid body or id |
| 401 | `ACCESS_TOKEN_INVALID` | Missing or invalid access token |
| 404 | `ACCOUNT_NOT_FOUND` | Account does not exist or belongs to another user |
| 403 | `ACCOUNT_NOT_EDITABLE` | Attempt to delete a default account |
| 409 | `ACCOUNT_ALREADY_EXISTS` | Duplicate account name |
