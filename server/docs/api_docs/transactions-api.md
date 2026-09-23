# Transactions API

API dùng chung cho cả khoản thu và khoản chi. Base URL local: `http://localhost:3000/api/v1`. Mọi endpoint yêu cầu `Authorization: Bearer <accessToken>`.

## Kiểu dữ liệu

```ts
type TransactionType = 'income' | 'expense';

interface Transaction {
  id: number;
  userId: number;
  categoryId: number;
  type: TransactionType;
  title: string;
  amount: string; // Decimal được serialize thành chuỗi
  transactionDate: string; // ISO 8601
  notes: string | null;
  createdAt: string;
  updatedAt: string;
  category: {
    id: number;
    name: string;
    isDefault: boolean;
    type: TransactionType;
  };
}
```

Danh mục phải thuộc cùng `type` với giao dịch. Người dùng chỉ truy cập được giao dịch của chính mình.

## Tạo giao dịch

`POST /transactions`

```json
{
  "type": "income",
  "title": "Lương tháng 9",
  "amount": 20000000,
  "transactionDate": "2026-09-23",
  "categoryId": 9,
  "notes": "Lương chính"
}
```

Quy tắc:

- `type`: bắt buộc, `income` hoặc `expense`.
- `title`: bắt buộc, không chỉ chứa khoảng trắng, tối đa 150 ký tự.
- `amount`: từ `0.01` đến `9999999999999.99`, tối đa hai chữ số thập phân.
- `transactionDate`: ngày hoặc date-time ISO 8601.
- `categoryId`: số nguyên dương, danh mục phải truy cập được và cùng loại.
- `notes`: không bắt buộc, tối đa 2.000 ký tự; chuỗi rỗng được lưu thành `null`.

Response `201` trả `Transaction` đầy đủ trong `data`.

## Danh sách giao dịch

`GET /transactions`

Query:

| Field | Mặc định | Quy tắc |
| --- | --- | --- |
| `page` | `1` | Số nguyên ≥ 1 |
| `limit` | `20` | 1–100 |
| `type` | Không lọc | `income` hoặc `expense` |
| `categoryId` | Không lọc | Số nguyên ≥ 1 |
| `from` / `to` | Không lọc | ISO 8601; ngày `to` bao gồm hết ngày |
| `sortBy` | `transactionDate` | `transactionDate`, `amount`, `createdAt` |
| `sortOrder` | `desc` | `asc` hoặc `desc` |

Response `200`:

```json
{
  "statusCode": 200,
  "message": "Transactions retrieved successfully",
  "data": {
    "items": [],
    "pagination": { "page": 1, "limit": 20, "total": 0, "totalPages": 0 }
  }
}
```

## Xu hướng chi tiêu

`GET /transactions/trend`

Endpoint cộng các giao dịch theo `type` của user hiện tại và luôn trả đủ bucket trong khoảng thời gian, kể cả bucket có số tiền `0`.

Query:

| Field | Mặc định | Quy tắc |
| --- | --- | --- |
| `type` | `expense` | `income` hoặc `expense` |
| `period` | `month` | `week`, `month` hoặc `year` |
| `date` | Ngày hiện tại | `YYYY-MM-DD`, dùng làm ngày neo để xác định tuần/tháng/năm |

- `week`: tuần bắt đầu từ thứ Hai, `items` là 7 ngày.
- `month`: `items` là từng ngày trong tháng.
- `year`: `items` là 12 tháng, ngày đại diện là ngày đầu tháng (`YYYY-MM-01`).

Ví dụ `GET /transactions/trend?period=year&date=2026-09-23`:

```json
{
  "statusCode": 200,
  "message": "Transaction trend retrieved successfully",
  "data": {
    "type": "expense",
    "period": "year",
    "granularity": "month",
    "from": "2026-01-01",
    "to": "2027-01-01",
    "items": [
      { "date": "2026-01-01", "amount": "1200000" },
      { "date": "2026-02-01", "amount": "0" }
    ]
  }
}
```

## Chi tiết, cập nhật và xóa

- `GET /transactions/:id`: trả một giao dịch.
- `PATCH /transactions/:id`: mọi field đều không bắt buộc; nếu đổi `type` hoặc `categoryId`, cặp mới phải cùng loại.
- `DELETE /transactions/:id`: xóa giao dịch và trả `data: null`.

## Mã lỗi

| HTTP | `errorCode` | Ý nghĩa |
| --- | --- | --- |
| 400 | `VALIDATION_ERROR` | Body/query/id không hợp lệ hoặc `from > to` |
| 401 | `ACCESS_TOKEN_INVALID`, `ACCESS_TOKEN_EXPIRED` | Phiên không hợp lệ hoặc hết hạn |
| 404 | `CATEGORY_NOT_FOUND` | Danh mục không tồn tại, không thuộc user, hoặc khác loại |
| 404 | `TRANSACTION_NOT_FOUND` | Giao dịch không tồn tại hoặc không thuộc user |

Các endpoint `/expenses` cũ vẫn được giữ để tương thích và chỉ thao tác trên giao dịch `expense`.
