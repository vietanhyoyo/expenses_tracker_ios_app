# Expense Tracker Backend Implementation Plan

## 1. Project Goal

Build a production-style backend for a simplified personal expense tracking mobile application.

The backend must:

- Use **NestJS** with **TypeScript**.
- Use **MySQL 8** as the database.
- Use **Prisma ORM** for database access and migrations.
- Run both the NestJS API and MySQL through **Docker Compose**.
- Provide secure email/password authentication.
- Use:
  - **Access Token:** expires in **1 day**.
  - **Refresh Token:** expires in **7 days**.
- Support refresh token rotation and token revocation.
- Provide consistent HTTP status codes and standardized success/error responses.
- Support expense CRUD operations.
- Support predefined and custom expense categories.
- Support pagination, filtering, and sorting.
- Include Swagger API documentation.
- Include automated tests.
- Include a README with local setup instructions.

This document covers **backend implementation only**.

---

# 2. Tech Stack

Use the following stack unless there is a strong implementation reason to change it:

- Node.js
- NestJS
- TypeScript
- MySQL 8
- Prisma ORM
- Docker
- Docker Compose
- Passport
- JWT
- bcrypt
- class-validator
- class-transformer
- Swagger / OpenAPI
- Jest
- Supertest

Recommended NestJS packages:

```bash
@nestjs/config
@nestjs/jwt
@nestjs/passport
@nestjs/swagger
@nestjs/throttler
passport
passport-jwt
bcrypt
class-validator
class-transformer
helmet
prisma
@prisma/client
```

---

# 3. High-Level Architecture

Use a modular monolith with a **layer-first** NestJS architecture.

```text
Mobile Client
    |
    | REST API
    v
Controllers
    |
    v
Services
    |
    | Business rules and authorization
    v
Repositories
    |
    | Prisma queries and transactions
    v
Prisma ORM
    |
    v
MySQL 8

Cross-cutting layers:

Modules      -> NestJS dependency wiring
DTOs         -> request validation and Swagger metadata
Entities     -> application/domain response shapes
Strategies   -> JWT authentication
Common       -> guards, decorators, filters, interceptors and shared types
Database     -> Prisma Client lifecycle
```

Feature ownership is still expressed through NestJS modules:

```text
AppModule
├── AuthModule
├── UsersModule
├── CategoriesModule
├── ExpensesModule
└── PrismaModule
```

Request flow:

```text
Client -> Controller -> Service -> Repository -> Prisma -> MySQL
Client <- Controller <- Service <- Repository <- Prisma <- MySQL
```

Docker architecture:

```text
docker compose
|
+-- api
|    NestJS
|
+-- mysql
     MySQL 8
```

---

# 4. Implemented Project Structure

Use the following layer-first structure. Files are grouped by technical responsibility rather than by feature.

```text
src/
├── common/
│   ├── constants/
│   │   └── error-codes.constant.ts
│   ├── decorators/
│   │   └── current-user.decorator.ts
│   ├── filters/
│   │   └── http-exception.filter.ts
│   ├── guards/
│   │   ├── jwt-auth.guard.ts
│   │   └── refresh-token.guard.ts
│   ├── interceptors/
│   │   └── response.interceptor.ts
│   ├── interfaces/
│   └── utils/
├── config/
│   └── env.validation.ts
├── controllers/
│   ├── auth.controller.ts
│   ├── users.controller.ts
│   ├── categories.controller.ts
│   └── expenses.controller.ts
├── database/
│   └── prisma.service.ts
├── dto/
│   ├── register.dto.ts
│   ├── login.dto.ts
│   ├── refresh-token.dto.ts
│   ├── create-category.dto.ts
│   ├── update-category.dto.ts
│   ├── create-expense.dto.ts
│   ├── update-expense.dto.ts
│   └── query-expenses.dto.ts
├── entities/
│   ├── auth.entity.ts
│   ├── user.entity.ts
│   ├── category.entity.ts
│   └── expense.entity.ts
├── modules/
│   ├── auth.module.ts
│   ├── users.module.ts
│   ├── categories.module.ts
│   ├── expenses.module.ts
│   └── prisma.module.ts
├── repositories/
│   ├── auth.repository.ts
│   ├── users.repository.ts
│   ├── categories.repository.ts
│   └── expenses.repository.ts
├── services/
│   ├── auth.service.ts
│   ├── users.service.ts
│   ├── categories.service.ts
│   └── expenses.service.ts
├── strategies/
│   ├── jwt.strategy.ts
│   └── refresh-token.strategy.ts
├── app.module.ts
└── main.ts
```

Layer responsibilities:

- `controllers`: define routes, HTTP status codes, guards, and request DTOs.
- `services`: implement business rules, authorization decisions, and use cases.
- `repositories`: own Prisma queries, persistence details, and database transactions.
- `entities`: define application-facing domain and response shapes; they do not persist data themselves.
- `dto`: validate and transform incoming request data.
- `modules`: connect controllers, services, repositories, strategies, and shared providers.
- `database`: manage the Prisma Client connection lifecycle.
- `common`: provide reusable cross-cutting infrastructure.

Prisma structure:

```text
prisma/
├── schema.prisma
├── seed.ts
└── migrations/
```

Root project structure:

```text
.
├── src/
├── prisma/
├── test/
├── Dockerfile
├── docker-compose.yml
├── .dockerignore
├── .env.example
├── package.json
├── tsconfig.json
└── README.md
```

---

# 5. Database Design

Use four main tables:

- `users`
- `categories`
- `expenses`
- `refresh_tokens`

---

# 6. User Model

Suggested fields:

```text
id
email
password_hash
created_at
updated_at
```

Requirements:

- `id` should be the primary key.
- `email` must be unique.
- Email comparison should be case-insensitive at the application level.
- Normalize email before storing it.
- Never store plaintext passwords.
- Passwords must be hashed using bcrypt.
- Do not return `password_hash` from public API responses.

Example Prisma concept:

```prisma
model User {
  id            Int            @id @default(autoincrement())
  email         String         @unique
  passwordHash  String         @map("password_hash")
  expenses      Expense[]
  categories    Category[]
  refreshTokens RefreshToken[]
  createdAt     DateTime       @default(now()) @map("created_at")
  updatedAt     DateTime       @updatedAt @map("updated_at")

  @@map("users")
}
```

---

# 7. Category Model

Categories must support both:

1. Global predefined categories.
2. User-created custom categories.

Suggested fields:

```text
id
name
user_id nullable
is_default
created_at
updated_at
```

Rules:

- Default categories:
  - `user_id = NULL`
  - `is_default = true`
- Custom categories:
  - `user_id = current user ID`
  - `is_default = false`
- Users can read:
  - all default categories
  - their own custom categories
- Users cannot edit or delete default categories.
- Users cannot edit or delete another user's category.
- Prevent duplicate custom category names for the same user.
- Prefer case-insensitive duplicate checks.

Seed the following default categories:

```text
Food
Transportation
Entertainment
Utilities
Shopping
Health
Education
Other
```

The seed must be **idempotent**.

---

# 8. Expense Model

Suggested fields:

```text
id
user_id
category_id
title
amount
expense_date
location nullable
notes nullable
created_at
updated_at
```

Requirements:

- Every expense belongs to exactly one user.
- Every expense belongs to exactly one category.
- `amount` must use a decimal type.
- Do not use floating point storage for currency.

Recommended database type:

```text
DECIMAL(15,2)
```

Validation rules:

- `title`
  - required
  - string
  - trimmed
  - reasonable max length, for example 150
- `amount`
  - required
  - numeric
  - greater than 0
- `expenseDate`
  - required
  - valid ISO date
- `categoryId`
  - required
  - existing category
  - must be either:
    - a default category, or
    - a custom category owned by the current user
- `location`
  - optional
  - max length, for example 255
- `notes`
  - optional
  - max length, for example 2000

---

# 9. Refresh Token Model

Use a dedicated refresh token table.

Suggested fields:

```text
id
user_id
token_hash
expires_at
revoked_at nullable
created_at
```

Requirements:

- Never store a raw refresh token in the database.
- Store only a secure hash of the refresh token.
- A refresh token must be revocable.
- A refresh token must have an explicit expiration timestamp.
- Use refresh token rotation.

Recommended flow:

```text
Refresh Token A
    |
    | POST /auth/refresh
    v
Validate JWT
    |
Validate token hash in database
    |
Check not expired
    |
Check not revoked
    |
Revoke Token A
    |
Generate Access Token B
Generate Refresh Token B
    |
Store hash of Token B
    |
Return Token B pair
```

---

# 10. Authentication Requirements

Authentication is email/password based.

Token lifetime:

```text
Access Token  = 1 day
Refresh Token = 7 days
```

Environment configuration:

```env
JWT_ACCESS_SECRET=change-me
JWT_REFRESH_SECRET=change-me
JWT_ACCESS_EXPIRES_IN=1d
JWT_REFRESH_EXPIRES_IN=7d
```

JWT payload should contain only minimal identity information.

Example:

```json
{
  "sub": 123,
  "email": "user@example.com"
}
```

Do not put the following inside JWTs:

- password hash
- raw refresh token
- database credentials
- unnecessary sensitive data

---

# 11. Authentication API

Base API prefix:

```text
/api/v1
```

## 11.1 Register

```http
POST /api/v1/auth/register
```

Request:

```json
{
  "email": "user@example.com",
  "password": "12345678"
}
```

Validation:

- valid email
- password minimum length: at least 8 characters
- normalize email
- reject duplicate email

Flow:

```text
Validate request
-> Normalize email
-> Check if email exists
-> Hash password using bcrypt
-> Create user
-> Generate access token
-> Generate refresh token
-> Store refresh token hash
-> Return user and tokens
```

Status:

```text
201 Created
```

---

# 12. Login API

```http
POST /api/v1/auth/login
```

Request:

```json
{
  "email": "user@example.com",
  "password": "12345678"
}
```

Flow:

```text
Normalize email
-> Find user
-> Compare password hash
-> If invalid, return generic invalid credentials error
-> Generate access token
-> Generate refresh token
-> Store refresh token hash
-> Return tokens
```

Status:

```text
200 OK
```

Important:

Do not reveal whether the email or password was incorrect.

Use a generic message such as:

```text
Email or password is incorrect
```

---

# 13. Refresh Token API

```http
POST /api/v1/auth/refresh
```

Request:

```json
{
  "refreshToken": "..."
}
```

Flow:

```text
Verify refresh JWT
-> Find active refresh token record
-> Compare token hash
-> Check expiration
-> Check revoked status
-> Revoke existing token
-> Generate new access token
-> Generate new refresh token
-> Store new refresh token hash
-> Return new token pair
```

Status:

```text
200 OK
```

Use refresh token rotation for every successful refresh operation.

---

# 14. Logout API

```http
POST /api/v1/auth/logout
```

The endpoint should revoke the provided active refresh token.

Preferred behavior:

- Access token identifies the user.
- Request includes the active refresh token.
- Backend revokes only that refresh token.

Optional bonus endpoint:

```http
POST /api/v1/auth/logout-all
```

This endpoint may revoke all active refresh tokens for the current user.

Do not implement `logout-all` until all required functionality is finished.

---

# 15. Current User API

```http
GET /api/v1/users/me
```

Protected by access token authentication.

Response should contain public user information only.

Example:

```json
{
  "statusCode": 200,
  "message": "User retrieved successfully",
  "data": {
    "id": 1,
    "email": "user@example.com",
    "createdAt": "2026-09-22T00:00:00.000Z"
  }
}
```

---

# 16. Category API

## Get Categories

```http
GET /api/v1/categories
```

Return:

- all system default categories
- current user's custom categories

---

## Create Custom Category

```http
POST /api/v1/categories
```

Request:

```json
{
  "name": "Gym"
}
```

Rules:

- name required
- trim whitespace
- prevent duplicate category name for the same user
- created category belongs to current user
- `is_default = false`

Status:

```text
201 Created
```

---

## Update Custom Category

```http
PATCH /api/v1/categories/:id
```

Rules:

- category must exist
- category must belong to the current user
- default categories cannot be modified

---

## Delete Custom Category

```http
DELETE /api/v1/categories/:id
```

Rules:

- category must exist
- category must belong to current user
- default category cannot be deleted

Before deletion, define behavior when the category is already used by expenses.

Preferred behavior for this project:

- Reject deletion with `409 Conflict` if the category is currently referenced by one or more expenses.

This avoids accidental data mutation.

---

# 17. Expense API

## Create Expense

```http
POST /api/v1/expenses
```

Example request:

```json
{
  "title": "Lunch",
  "amount": 120000,
  "expenseDate": "2026-09-22",
  "categoryId": 1,
  "location": "Can Tho",
  "notes": "Lunch with friends"
}
```

Status:

```text
201 Created
```

---

## List Expenses

```http
GET /api/v1/expenses
```

Must support:

- pagination
- category filtering
- date range filtering
- sorting

Suggested query parameters:

```text
page
limit
categoryId
from
to
sortBy
sortOrder
```

Example:

```http
GET /api/v1/expenses?page=1&limit=20&categoryId=2&from=2026-09-01&to=2026-09-30&sortBy=expenseDate&sortOrder=desc
```

Defaults:

```text
page = 1
limit = 20
sortBy = expenseDate
sortOrder = desc
```

Suggested allowed values:

```text
sortBy:
- expenseDate
- amount
- createdAt

sortOrder:
- asc
- desc
```

Set a maximum `limit`, for example:

```text
100
```

Never return another user's expenses.

---

# 18. Expense Detail

```http
GET /api/v1/expenses/:id
```

The backend must scope the lookup by both:

```text
expense.id
AND
expense.user_id = currentUser.id
```

If the expense does not exist or belongs to another user, return:

```text
404 Not Found
```

Do not reveal whether a resource owned by another user exists.

---

# 19. Update Expense

```http
PATCH /api/v1/expenses/:id
```

Rules:

- current user must own the expense
- validate every provided field
- if `categoryId` changes, validate category access again
- support partial updates

---

# 20. Delete Expense

```http
DELETE /api/v1/expenses/:id
```

Rules:

- current user must own the expense
- if not found under the current user, return `404`

Preferred response:

```text
200 OK
```

Example:

```json
{
  "statusCode": 200,
  "message": "Expense deleted successfully",
  "data": null
}
```

Use this format to keep client response handling consistent.

---

# 21. HTTP Status Code Standard

Use clear and consistent HTTP status codes.

| Situation | Status |
|---|---:|
| Successful request | 200 |
| Resource created | 201 |
| Invalid input | 400 |
| Invalid credentials | 401 |
| Missing access token | 401 |
| Expired access token | 401 |
| Invalid refresh token | 401 |
| Expired refresh token | 401 |
| Authenticated but forbidden | 403 |
| Resource not found | 404 |
| Duplicate email | 409 |
| Duplicate category | 409 |
| Category currently in use | 409 |
| Unexpected server failure | 500 |

---

# 22. Standard Success Response

All successful responses should follow a common structure.

Example:

```json
{
  "statusCode": 200,
  "message": "Success",
  "data": {}
}
```

For list endpoints:

```json
{
  "statusCode": 200,
  "message": "Expenses retrieved successfully",
  "data": {
    "items": [],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 45,
      "totalPages": 3
    }
  }
}
```

Implement a global response interceptor if practical.

Do not double-wrap endpoints that already intentionally return the standardized format.

---

# 23. Standard Error Response

All errors should follow a common structure.

Example validation error:

```json
{
  "statusCode": 400,
  "errorCode": "VALIDATION_ERROR",
  "message": "Invalid request data",
  "errors": [
    {
      "field": "amount",
      "message": "Amount must be greater than 0"
    }
  ],
  "timestamp": "2026-09-22T06:30:00.000Z",
  "path": "/api/v1/expenses"
}
```

Example authentication error:

```json
{
  "statusCode": 401,
  "errorCode": "INVALID_CREDENTIALS",
  "message": "Email or password is incorrect",
  "timestamp": "2026-09-22T06:30:00.000Z",
  "path": "/api/v1/auth/login"
}
```

Example conflict:

```json
{
  "statusCode": 409,
  "errorCode": "EMAIL_ALREADY_EXISTS",
  "message": "Email already exists",
  "timestamp": "2026-09-22T06:30:00.000Z",
  "path": "/api/v1/auth/register"
}
```

---

# 24. Error Codes

Create centralized error code constants.

At minimum:

```text
VALIDATION_ERROR
INVALID_CREDENTIALS
EMAIL_ALREADY_EXISTS
UNAUTHORIZED
FORBIDDEN
ACCESS_TOKEN_INVALID
ACCESS_TOKEN_EXPIRED
REFRESH_TOKEN_INVALID
REFRESH_TOKEN_EXPIRED
REFRESH_TOKEN_REVOKED
CATEGORY_NOT_FOUND
CATEGORY_ALREADY_EXISTS
CATEGORY_NOT_EDITABLE
CATEGORY_IN_USE
EXPENSE_NOT_FOUND
INTERNAL_SERVER_ERROR
```

The mobile client should be able to use `errorCode` without parsing human-readable messages.

---

# 25. Global Error Handling

Implement a global NestJS exception filter.

Responsibilities:

- normalize built-in NestJS HTTP exceptions
- normalize validation errors
- normalize Prisma errors
- handle unexpected exceptions
- log internal error details on the server
- never expose internal stack traces to the client in production
- never expose:
  - SQL queries
  - database passwords
  - JWT secrets
  - stack traces
  - internal implementation details

Unknown failures should return:

```text
500 Internal Server Error
```

Example public response:

```json
{
  "statusCode": 500,
  "errorCode": "INTERNAL_SERVER_ERROR",
  "message": "An unexpected error occurred",
  "timestamp": "...",
  "path": "..."
}
```

---

# 26. Validation Configuration

Configure a global `ValidationPipe`.

Recommended options:

```ts
{
  whitelist: true,
  forbidNonWhitelisted: true,
  transform: true
}
```

Use DTO decorators such as:

```text
@IsEmail()
@IsString()
@IsOptional()
@IsNumber()
@IsPositive()
@IsDateString()
@MinLength()
@MaxLength()
@IsInt()
@Min()
@Max()
@IsIn()
```

Reject unknown request fields.

---

# 27. Authentication Guards

Implement:

```text
JwtAuthGuard
RefreshTokenGuard
```

Use `JwtAuthGuard` for:

- `/users/me`
- category APIs
- expense APIs
- logout

The access token should be supplied as:

```http
Authorization: Bearer <access-token>
```

---

# 28. Current User Decorator

Implement a reusable decorator:

```ts
@CurrentUser()
```

It should return the authenticated user identity extracted by the JWT strategy.

Avoid repeatedly reading `request.user` directly from controllers.

---

# 29. Security Requirements

Implement at least the following:

- bcrypt password hashing
- JWT access token validation
- separate access and refresh secrets
- refresh token hashing in database
- refresh token rotation
- refresh token revocation
- Helmet
- configurable CORS
- DTO validation
- environment variable configuration
- database uniqueness constraints
- authorization checks on all user-owned resources
- rate limiting on authentication endpoints

Suggested rate-limited endpoints:

```text
POST /auth/register
POST /auth/login
POST /auth/refresh
```

A simple project-level default such as approximately 10 requests per minute per client is sufficient.

Do not overcomplicate rate limiting.

---

# 30. Environment Variables

Provide `.env.example`.

Example:

```env
NODE_ENV=development
PORT=3000

DATABASE_URL=mysql://expense_user:expense_password@mysql:3306/expense_tracker

MYSQL_DATABASE=expense_tracker
MYSQL_USER=expense_user
MYSQL_PASSWORD=expense_password
MYSQL_ROOT_PASSWORD=root_password

JWT_ACCESS_SECRET=replace-with-secure-access-secret
JWT_REFRESH_SECRET=replace-with-secure-refresh-secret
JWT_ACCESS_EXPIRES_IN=1d
JWT_REFRESH_EXPIRES_IN=7d

BCRYPT_SALT_ROUNDS=12

CORS_ORIGIN=*
```

Do not commit real secrets.

---

# 31. Docker Requirements

Create:

```text
Dockerfile
docker-compose.yml
.dockerignore
```

Docker Compose must run:

```text
api
mysql
```

MySQL should use a persistent volume.

Example architecture:

```text
services:
  mysql:
    image: mysql:8
    volume: mysql_data

  api:
    build: .
    depends_on:
      mysql:
        condition: service_healthy
```

Configure a MySQL health check.

The API should not attempt to start database-dependent initialization before MySQL is ready.

---

# 32. Application Startup Flow

Target startup behavior:

```text
docker compose up --build
        |
        v
MySQL starts
        |
        v
MySQL health check passes
        |
        v
NestJS container starts
        |
        v
Prisma migration is applied
        |
        v
Default categories are seeded
        |
        v
NestJS API starts
```

Avoid race conditions between NestJS startup and MySQL readiness.

---

# 33. Prisma Migrations

Use Prisma migrations.

Development:

```bash
npx prisma migrate dev
```

Container or deployment-style startup:

```bash
npx prisma migrate deploy
```

Do not use destructive schema resets as part of normal Docker startup.

---

# 34. Default Category Seed

Create an idempotent seed script.

Seed:

```text
Food
Transportation
Entertainment
Utilities
Shopping
Health
Education
Other
```

Running the seed multiple times must not create duplicate records.

---

# 35. Swagger Documentation

Expose Swagger at:

```http
/api/docs
```

Document:

- authentication endpoints
- request DTOs
- response DTOs where practical
- HTTP status codes
- Bearer authentication
- categories
- expenses
- pagination parameters
- filter parameters
- sorting parameters

Configure Swagger Bearer authentication so a reviewer can authenticate and test protected endpoints directly.

---

# 36. API Endpoint Summary

## Authentication

```text
POST   /api/v1/auth/register
POST   /api/v1/auth/login
POST   /api/v1/auth/refresh
POST   /api/v1/auth/logout
```

Optional:

```text
POST   /api/v1/auth/logout-all
```

## User

```text
GET    /api/v1/users/me
```

## Categories

```text
GET    /api/v1/categories
POST   /api/v1/categories
PATCH  /api/v1/categories/:id
DELETE /api/v1/categories/:id
```

## Expenses

```text
POST   /api/v1/expenses
GET    /api/v1/expenses
GET    /api/v1/expenses/:id
PATCH  /api/v1/expenses/:id
DELETE /api/v1/expenses/:id
```

---

# 37. Implementation Phases

The coding agent should implement the project in the following order.

---

## Phase 1: Bootstrap

Tasks:

- Create NestJS project.
- Configure TypeScript.
- Install required dependencies.
- Configure `ConfigModule`.
- Add global API prefix `/api/v1`.
- Add Swagger.
- Add Helmet.
- Add CORS configuration.
- Add global validation pipe.
- Create Dockerfile.
- Create docker-compose.yml.
- Add MySQL container.
- Add MySQL health check.
- Add `.env.example`.

Acceptance criteria:

```text
docker compose up --build
```

starts MySQL and NestJS successfully.

`GET /api/docs` must load Swagger.

---

## Phase 2: Prisma and Database

Tasks:

- Install Prisma.
- Create `PrismaModule` under `src/modules` and `PrismaService` under `src/database`.
- Create repository classes for authentication, users, categories, and expenses.
- Keep all Prisma queries and transactions inside repositories.
- Define:
  - User
  - Category
  - Expense
  - RefreshToken
- Add indexes and uniqueness constraints.
- Create first migration.
- Create idempotent category seed.
- Verify persistence through Docker volume.

Acceptance criteria:

- migrations can run from a clean database
- seed can run repeatedly without duplicates
- NestJS can connect to MySQL successfully

---

## Phase 3: Global Response and Error Handling

Tasks:

- Create error code constants.
- Create response interceptor.
- Create global exception filter.
- Convert validation errors to standardized format.
- Convert expected Prisma conflicts to meaningful HTTP responses.
- Protect internal error details.

Acceptance criteria:

All APIs return consistent success and error payloads.

---

## Phase 4: Authentication

Implement in this order:

1. Register
2. Login
3. JWT access strategy
4. JWT guard
5. `GET /users/me`
6. Refresh token generation
7. Refresh token persistence
8. Refresh token rotation
9. Logout / revocation

Acceptance criteria:

- access token expires after one day
- refresh token expires after seven days
- raw refresh tokens are never stored
- revoked refresh token cannot be reused
- refresh rotation invalidates the previous refresh token
- protected APIs reject missing or invalid access tokens

---

## Phase 5: Categories

Tasks:

- return default + current-user custom categories
- create custom categories
- edit custom categories
- delete custom categories
- protect system categories
- prevent access to another user's categories
- reject duplicate custom category names
- reject deletion of categories currently in use

Acceptance criteria:

Users cannot modify default categories or categories belonging to another user.

---

## Phase 6: Expenses

Implement:

1. Create expense
2. List expenses
3. Pagination
4. Category filter
5. Date range filter
6. Sorting
7. Expense detail
8. Update expense
9. Delete expense

Acceptance criteria:

Every expense query must be user-scoped.

No user may access another user's expense by guessing IDs.

---

## Phase 7: Testing

Add unit tests and E2E tests.

Minimum important cases are listed below.

---

# 38. Authentication Tests

Test:

```text
register success
register duplicate email
register invalid email
register invalid password

login success
login invalid email/password
login does not expose whether email exists

protected endpoint without token
protected endpoint with invalid token

refresh success
refresh expired token
refresh invalid token
refresh revoked token
refresh token rotation
old refresh token cannot be reused

logout success
logged-out refresh token cannot be reused
```

---

# 39. Category Tests

Test:

```text
list default categories
create custom category
reject empty category name
reject duplicate category name
update own custom category
cannot update default category
cannot update another user's category
delete own unused category
cannot delete default category
cannot delete another user's category
cannot delete category that is used by an expense
```

---

# 40. Expense Tests

Test:

```text
create expense successfully
reject amount <= 0
reject invalid date
reject inaccessible category
reject nonexistent category

list only own expenses
pagination works
category filter works
date range filter works
sorting works

get own expense
cannot read another user's expense

update own expense
cannot update another user's expense

delete own expense
cannot delete another user's expense
```

---

# 41. E2E Happy Path

Create at least one end-to-end test covering:

```text
Register
-> Login
-> Get categories
-> Create custom category
-> Create expense
-> List expenses
-> Get expense detail
-> Update expense
-> Refresh access token
-> Delete expense
-> Logout
```

---

# 42. Logging

Use NestJS logging or a simple structured logger.

Log:

- application startup
- unexpected errors
- database connection failure
- failed system initialization

Do not log:

- plaintext passwords
- raw access tokens
- raw refresh tokens
- JWT secrets
- database credentials

Avoid unnecessary logging complexity for this assignment.

---

# 43. README Requirements

The final README must include:

## Overview

Explain what the backend does.

## Tech Stack

List:

- NestJS
- TypeScript
- MySQL
- Prisma
- Docker

## Requirements

Mention Docker and Docker Compose.

## Setup

Example:

```bash
git clone <repository>
cd <project>

cp .env.example .env

docker compose up --build
```

## Database Migration

Explain automatic startup behavior and manual migration command if needed.

## Seed

Explain how default categories are created.

## Swagger

Document:

```text
http://localhost:3000/api/docs
```

## Authentication

Explain:

```text
Access Token: 1 day
Refresh Token: 7 days
```

## Tests

Include commands such as:

```bash
npm run test
npm run test:e2e
```

If tests run inside Docker, document that workflow too.

## Architecture

Include a short layer-first architecture overview and the request flow from controller to MySQL.

---

# 44. Code Quality Rules

The coding agent should follow these rules:

- Keep controllers thin.
- Put business logic in services.
- Put database queries and transactions in repositories.
- Do not access Prisma directly from controllers or business services.
- Use entities for application-facing data shapes, not as database persistence objects.
- Reuse DTOs carefully.
- Avoid `any`.
- Use explicit return types where practical.
- Keep error handling centralized.
- Do not duplicate authorization logic unnecessarily.
- Use transactions when one operation changes multiple related database records.
- Do not add unnecessary abstractions.
- Do not introduce microservices.
- Do not add Redis unless a requirement truly needs it.
- Do not add queues or message brokers.
- Do not add unnecessary design patterns just to make the project look complex.

The project should be easy for a reviewer to understand.

---

# 45. Out of Scope

Do not implement these features unless all required work is complete and there is a clear reason:

```text
Forgot password
Email verification
Google OAuth
Facebook OAuth
Apple Sign-In
Role-based access control
Admin dashboard
Redis
Kafka
RabbitMQ
Microservices
GraphQL
Cloud deployment
Push notifications
Recurring expenses
Budget management
Analytics dashboard
Currency conversion
Receipt uploads
```

---

# 46. Definition of Done

The backend is considered complete when all of the following are true:

- NestJS runs successfully inside Docker.
- MySQL runs successfully inside Docker.
- MySQL data persists across container restarts.
- Prisma migrations work from a clean database.
- Default categories are seeded without duplication.
- Registration works.
- Login works.
- Passwords are securely hashed.
- Access tokens expire after 1 day.
- Refresh tokens expire after 7 days.
- Refresh tokens are hashed in the database.
- Refresh token rotation works.
- Logout revokes refresh tokens.
- Protected APIs require authentication.
- Users can retrieve default categories.
- Users can create custom categories.
- Users cannot modify system categories.
- Users cannot access another user's custom categories.
- Users can create expenses.
- Users can list their expenses.
- Expense pagination works.
- Expense filtering works.
- Expense sorting works.
- Users can edit their own expenses.
- Users can delete their own expenses.
- Users cannot access another user's expenses.
- Validation errors return HTTP 400 with a clear structure.
- Authentication errors return HTTP 401.
- Authorization errors return HTTP 403 where appropriate.
- Missing user-scoped resources return HTTP 404.
- Conflict conditions return HTTP 409.
- Unexpected failures return HTTP 500 without leaking internals.
- Swagger is available.
- Automated tests cover important flows.
- README contains complete local setup instructions.
- A reviewer can start the entire backend with Docker using only the README.

---

# 47. Final Deliverables

The coding agent must produce:

```text
NestJS source code
Prisma schema
Prisma migrations
Prisma seed
Dockerfile
docker-compose.yml
.env.example
Swagger configuration
Unit tests
E2E tests
README.md
```

The repository must be runnable locally with Docker without requiring external infrastructure.

---

# 48. Recommended Implementation Principle

Prioritize correctness, security, readability, and reviewer usability over unnecessary complexity.

The expected result is a clean modular monolithic backend that demonstrates:

- good NestJS structure
- REST API design
- authentication
- token lifecycle management
- authorization
- database modeling
- validation
- error handling
- Docker usage
- testing
- clear documentation
