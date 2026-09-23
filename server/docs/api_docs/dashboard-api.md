# Dashboard API

## Tổng quan theo tháng

`GET /dashboard/summary?month=YYYY-MM`

Yêu cầu `Authorization: Bearer <accessToken>`. `month` không bắt buộc; mặc định là tháng hiện tại theo UTC.

Response `200`:

```json
{
  "statusCode": 200,
  "message": "Dashboard summary retrieved successfully",
  "data": {
    "month": "2026-09",
    "totalBalance": "18750000",
    "monthlyIncome": "20000000",
    "monthlyExpense": "1250000",
    "monthlyBalance": "18750000"
  }
}
```

Ý nghĩa:

- `totalBalance`: tổng mọi khoản thu trừ tổng mọi khoản chi của user, không giới hạn tháng.
- `monthlyIncome`: tổng khoản thu trong tháng được chọn.
- `monthlyExpense`: tổng khoản chi trong tháng được chọn.
- `monthlyBalance`: `monthlyIncome - monthlyExpense`.
- Các giá trị tiền là chuỗi decimal để tránh sai số floating-point.

Lỗi:

| HTTP | `errorCode` | Ý nghĩa |
| --- | --- | --- |
| 400 | `VALIDATION_ERROR` | `month` không đúng định dạng `YYYY-MM` |
| 401 | `ACCESS_TOKEN_INVALID`, `ACCESS_TOKEN_EXPIRED` | Phiên không hợp lệ hoặc hết hạn |
