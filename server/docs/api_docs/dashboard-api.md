# Dashboard API

## Tổng quan theo tuần, tháng hoặc năm

`GET /dashboard/summary?period=week|month|year&date=YYYY-MM-DD`

Yêu cầu `Authorization: Bearer <accessToken>`. Hai query đều không bắt buộc;
mặc định là tháng hiện tại và ngày hiện tại theo UTC.

Response `200`:

```json
{
  "statusCode": 200,
  "message": "Dashboard summary retrieved successfully",
  "data": {
    "month": "2026-09",
    "period": "month",
    "from": "2026-09-01",
    "to": "2026-10-01",
    "totalBalance": "18750000",
    "monthlyIncome": "20000000",
    "monthlyExpense": "1250000",
    "monthlyBalance": "18750000"
  }
}
```

Ý nghĩa:

- `period`: khoảng thời gian được chọn: `week`, `month` hoặc `year`.
- `date`: ngày neo để xác định khoảng thời gian.
- `from`, `to`: cận bắt đầu (bao gồm) và kết thúc (không bao gồm) của khoảng lọc.
- `totalBalance`: tổng mọi khoản thu trừ tổng mọi khoản chi của user, không giới hạn
  khoảng thời gian.
- `monthlyIncome`, `monthlyExpense`: tổng khoản thu/chi trong khoảng được chọn.
- `monthlyBalance`: `monthlyIncome - monthlyExpense`.
- Các giá trị tiền là chuỗi decimal để tránh sai số floating-point.

Lỗi:

| HTTP | `errorCode` | Ý nghĩa |
| --- | --- | --- |
| 400 | `VALIDATION_ERROR` | `period` hoặc `date` không đúng định dạng |
| 401 | `ACCESS_TOKEN_INVALID`, `ACCESS_TOKEN_EXPIRED` | Phiên không hợp lệ hoặc hết hạn |
