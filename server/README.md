# Expense Tracker Backend

## Mô tả dự án

REST API cho ứng dụng quản lý chi tiêu cá nhân, hỗ trợ:

- Đăng ký, đăng nhập và refresh token rotation.
- Quản lý danh mục mặc định và danh mục cá nhân.
- Thêm, xem, sửa và xóa khoản chi tiêu.
- Quản lý chung khoản thu và khoản chi qua `/transactions`.
- Tổng số dư cùng tổng thu/chi từng tháng qua `/dashboard/summary`.
- Danh sách tài khoản mặc định và tài khoản cá nhân qua `/accounts` (Tiền mặt, Ví điện tử, Ngân hàng).
- Phân trang, lọc và sắp xếp chi tiêu.
- Phân quyền dữ liệu theo từng người dùng.
- Swagger API documentation.

## Tech stack

- NestJS, TypeScript
- MySQL 8
- Prisma ORM
- Passport JWT, bcrypt
- class-validator
- Swagger / OpenAPI
- Jest, Supertest
- Docker, Docker Compose

## Chạy local với Docker

Yêu cầu: Docker Engine và Docker Compose.

```bash
cd server
cp .env.example .env
docker compose up --build -d
```

Docker sẽ tự động khởi động MySQL, chạy Prisma migration, seed các danh mục mặc định và khởi động API.

- API: `http://localhost:3000/api/v1`
- Swagger: `http://localhost:3000/api/docs`
- MySQL: `localhost:3306`

Tài khoản seed để kiểm thử: `user@gmail.com` / `user123456@`.

Dừng ứng dụng:

```bash
docker compose down
```

Dữ liệu MySQL được lưu trong Docker volume `mysql_data` và không bị mất khi chạy `docker compose down`.

## Kiến trúc

Dự án sử dụng kiến trúc layer-first:

```text
src/
├── common/          # Guard, decorator, filter, interceptor và kiểu dùng chung
├── config/          # Cấu hình và kiểm tra biến môi trường
├── controllers/     # Xử lý HTTP request/response
├── database/        # Kết nối và vòng đời Prisma Client
├── dto/             # Kiểm tra dữ liệu đầu vào
├── entities/        # Kiểu dữ liệu domain và response
├── modules/         # Khai báo dependency của NestJS
├── repositories/    # Truy vấn cơ sở dữ liệu bằng Prisma
├── services/        # Business logic
├── strategies/      # JWT authentication strategies
├── app.module.ts
└── main.ts
```

Luồng xử lý chính:

```text
Request → Controller → Service → Repository → Prisma → MySQL
```
