import request from 'supertest';

interface ApiEnvelope<T> {
  statusCode: number;
  message: string;
  data: T;
}

interface Tokens {
  accessToken: string;
  refreshToken: string;
}

interface Category {
  id: number;
  name: string;
  type: 'income' | 'expense';
  colorHex: string;
}

interface Expense {
  id: number;
  title: string;
}

interface ErrorEnvelope {
  errorCode: string;
  errors?: unknown[];
}

interface ExpenseList {
  items: Expense[];
}

interface Transaction extends Expense {
  type: 'income' | 'expense';
  amount: string;
  transactionDate: string;
}

interface DashboardSummary {
  month: string;
  totalBalance: string;
  monthlyIncome: string;
  monthlyExpense: string;
  monthlyBalance: string;
}

interface Account {
  id: number;
  name: string;
  type: 'cash' | 'ewallet' | 'bank';
  initialBalance: string;
  isDefault: boolean;
}

const api = request(process.env.E2E_BASE_URL ?? 'http://localhost:3000');

describe('Expense Tracker API (e2e)', () => {
  it('runs the complete authenticated expense workflow', async () => {
    const unique = `${Date.now()}-${Math.random().toString(16).slice(2)}`;
    const email = `e2e-${unique}@example.com`;
    const password = 'test-password-123';

    const register = await api
      .post('/api/v1/auth/register')
      .send({ email, password })
      .expect(201);
    expect((register.body as ApiEnvelope<unknown>).statusCode).toBe(201);

    const login = await api
      .post('/api/v1/auth/login')
      .send({ email, password })
      .expect(200);
    const loginData = (login.body as ApiEnvelope<Tokens>).data;

    const accounts = await api
      .get('/api/v1/accounts')
      .set('Authorization', `Bearer ${loginData.accessToken}`)
      .expect(200);
    const accountValues = (accounts.body as ApiEnvelope<Account[]>).data;
    expect(accountValues.map((account) => account.type)).toEqual(
      expect.arrayContaining(['cash', 'ewallet', 'bank']),
    );

    const categories = await api
      .get('/api/v1/categories')
      .set('Authorization', `Bearer ${loginData.accessToken}`)
      .expect(200);
    expect(
      (categories.body as ApiEnvelope<Category[]>).data.length,
    ).toBeGreaterThanOrEqual(8);

    const customCategory = await api
      .post('/api/v1/categories')
      .set('Authorization', `Bearer ${loginData.accessToken}`)
      .send({ name: `Gym ${unique}`, colorHex: '#7C3AED' })
      .expect(201);
    const category = (customCategory.body as ApiEnvelope<Category>).data;
    expect(category.colorHex).toBe('#7C3AED');

    const createdExpense = await api
      .post('/api/v1/expenses')
      .set('Authorization', `Bearer ${loginData.accessToken}`)
      .send({
        title: 'Monthly membership',
        amount: 250000,
        expenseDate: '2026-09-22',
        categoryId: category.id,
      })
      .expect(201);
    const expense = (createdExpense.body as ApiEnvelope<Expense>).data;

    const list = await api
      .get(
        `/api/v1/expenses?categoryId=${category.id}&sortBy=amount&sortOrder=desc`,
      )
      .set('Authorization', `Bearer ${loginData.accessToken}`)
      .expect(200);
    expect((list.body as ApiEnvelope<ExpenseList>).data.items).toHaveLength(1);

    await api
      .get(`/api/v1/expenses/${expense.id}`)
      .set('Authorization', `Bearer ${loginData.accessToken}`)
      .expect(200);

    await api
      .patch(`/api/v1/expenses/${expense.id}`)
      .set('Authorization', `Bearer ${loginData.accessToken}`)
      .send({ title: 'Updated membership' })
      .expect(200)
      .expect((response) => {
        expect((response.body as ApiEnvelope<Expense>).data.title).toBe(
          'Updated membership',
        );
      });

    const refresh = await api
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: loginData.refreshToken })
      .expect(200);
    const rotated = (refresh.body as ApiEnvelope<Tokens>).data;

    await api
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: loginData.refreshToken })
      .expect(401)
      .expect((response) => {
        expect((response.body as ErrorEnvelope).errorCode).toBe(
          'REFRESH_TOKEN_REVOKED',
        );
      });

    await api
      .delete(`/api/v1/expenses/${expense.id}`)
      .set('Authorization', `Bearer ${rotated.accessToken}`)
      .expect(200);

    await api
      .post('/api/v1/auth/logout')
      .set('Authorization', `Bearer ${rotated.accessToken}`)
      .send({ refreshToken: rotated.refreshToken })
      .expect(200);

    await api
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: rotated.refreshToken })
      .expect(401);
  }, 30_000);

  it('returns standardized validation and auth errors', async () => {
    const validation = await api
      .post('/api/v1/auth/register')
      .send({ email: 'invalid', password: 'short', unknown: true })
      .expect(400);
    expect((validation.body as ErrorEnvelope).errorCode).toBe(
      'VALIDATION_ERROR',
    );
    expect((validation.body as ErrorEnvelope).errors).toBeInstanceOf(Array);

    const unauthorized = await api.get('/api/v1/users/me').expect(401);
    expect((unauthorized.body as ErrorEnvelope).errorCode).toBe(
      'ACCESS_TOKEN_INVALID',
    );
  });

  it('enforces category rules and cross-user resource isolation', async () => {
    const unique = `${Date.now()}-${Math.random().toString(16).slice(2)}`;
    const password = 'test-password-123';
    const firstRegister = await api
      .post('/api/v1/auth/register')
      .send({ email: `owner-${unique}@example.com`, password })
      .expect(201);
    const first = (firstRegister.body as ApiEnvelope<Tokens>).data;

    const secondRegister = await api
      .post('/api/v1/auth/register')
      .send({ email: `other-${unique}@example.com`, password })
      .expect(201);
    const second = (secondRegister.body as ApiEnvelope<Tokens>).data;

    const defaultCategories = await api
      .get('/api/v1/categories')
      .set('Authorization', `Bearer ${first.accessToken}`)
      .expect(200);
    const defaultCategory = (
      defaultCategories.body as ApiEnvelope<Category[]>
    ).data.find((category) => category.type === 'expense')!;

    await api
      .patch(`/api/v1/categories/${defaultCategory.id}`)
      .set('Authorization', `Bearer ${first.accessToken}`)
      .send({ name: 'Cannot rename' })
      .expect(403)
      .expect((response) => {
        expect((response.body as ErrorEnvelope).errorCode).toBe(
          'CATEGORY_NOT_EDITABLE',
        );
      });

    const customResponse = await api
      .post('/api/v1/categories')
      .set('Authorization', `Bearer ${first.accessToken}`)
      .send({ name: `Private ${unique}`, colorHex: '#14B8A6' })
      .expect(201);
    const custom = (customResponse.body as ApiEnvelope<Category>).data;
    expect(custom.colorHex).toBe('#14B8A6');

    await api
      .post('/api/v1/categories')
      .set('Authorization', `Bearer ${first.accessToken}`)
      .send({ name: ` private   ${unique.toUpperCase()} ` })
      .expect(409);

    await api
      .patch(`/api/v1/categories/${custom.id}`)
      .set('Authorization', `Bearer ${first.accessToken}`)
      .send({ name: custom.name, colorHex: '#0ea5e9' })
      .expect(200)
      .expect((response) => {
        expect((response.body as ApiEnvelope<Category>).data.colorHex).toBe(
          '#0EA5E9',
        );
      });

    await api
      .patch(`/api/v1/categories/${custom.id}`)
      .set('Authorization', `Bearer ${second.accessToken}`)
      .send({ name: 'Stolen', colorHex: '#FFFFFF' })
      .expect(404);

    const expenseResponse = await api
      .post('/api/v1/expenses')
      .set('Authorization', `Bearer ${first.accessToken}`)
      .send({
        title: 'Private expense',
        amount: 10.5,
        expenseDate: '2026-09-22',
        categoryId: custom.id,
      })
      .expect(201);
    const expense = (expenseResponse.body as ApiEnvelope<Expense>).data;

    await api
      .delete(`/api/v1/categories/${custom.id}`)
      .set('Authorization', `Bearer ${first.accessToken}`)
      .expect(409)
      .expect((response) => {
        expect((response.body as ErrorEnvelope).errorCode).toBe(
          'CATEGORY_IN_USE',
        );
      });

    for (const method of ['get', 'patch', 'delete'] as const) {
      const operation = api[method](`/api/v1/expenses/${expense.id}`).set(
        'Authorization',
        `Bearer ${second.accessToken}`,
      );
      if (method === 'patch') operation.send({ title: 'Stolen' });
      await operation.expect(404);
    }

    await api
      .delete(`/api/v1/expenses/${expense.id}`)
      .set('Authorization', `Bearer ${first.accessToken}`)
      .expect(200);
    await api
      .delete(`/api/v1/categories/${custom.id}`)
      .set('Authorization', `Bearer ${first.accessToken}`)
      .expect(200);
  }, 30_000);

  it('serves transactions and dashboard summary for the seeded user', async () => {
    const login = await api
      .post('/api/v1/auth/login')
      .send({ email: 'user@gmail.com', password: 'user123456@' })
      .expect(200);
    const tokens = (login.body as ApiEnvelope<Tokens>).data;
    const authorization = `Bearer ${tokens.accessToken}`;

    const categoriesResponse = await api
      .get('/api/v1/categories')
      .set('Authorization', authorization)
      .expect(200);
    const categories = (categoriesResponse.body as ApiEnvelope<Category[]>)
      .data;
    const incomeCategory = categories.find(
      (category) => category.type === 'income',
    )!;
    const expenseCategory = categories.find(
      (category) => category.type === 'expense',
    )!;

    const beforeResponse = await api
      .get('/api/v1/dashboard/summary?month=2026-09')
      .set('Authorization', authorization)
      .expect(200);
    const before = (beforeResponse.body as ApiEnvelope<DashboardSummary>).data;

    const incomeResponse = await api
      .post('/api/v1/transactions')
      .set('Authorization', authorization)
      .send({
        type: 'income',
        title: 'Automated salary test',
        amount: 5000000,
        transactionDate: '2026-09-23',
        categoryId: incomeCategory.id,
      })
      .expect(201);
    const income = (incomeResponse.body as ApiEnvelope<Transaction>).data;

    const expenseResponse = await api
      .post('/api/v1/transactions')
      .set('Authorization', authorization)
      .send({
        type: 'expense',
        title: 'Automated expense test',
        amount: 1250000,
        transactionDate: '2026-09-23',
        categoryId: expenseCategory.id,
      })
      .expect(201);
    const expense = (expenseResponse.body as ApiEnvelope<Transaction>).data;

    const afterResponse = await api
      .get('/api/v1/dashboard/summary?month=2026-09')
      .set('Authorization', authorization)
      .expect(200);
    const after = (afterResponse.body as ApiEnvelope<DashboardSummary>).data;
    expect(Number(after.totalBalance) - Number(before.totalBalance)).toBe(
      3750000,
    );
    expect(Number(after.monthlyIncome) - Number(before.monthlyIncome)).toBe(
      5000000,
    );
    expect(Number(after.monthlyExpense) - Number(before.monthlyExpense)).toBe(
      1250000,
    );

    await api
      .get('/api/v1/transactions?type=income&from=2026-09-01&to=2026-09-30')
      .set('Authorization', authorization)
      .expect(200)
      .expect((response) => {
        const items = (response.body as ApiEnvelope<{ items: Transaction[] }>)
          .data.items;
        expect(items.some((item) => item.id === income.id)).toBe(true);
        expect(items.every((item) => item.type === 'income')).toBe(true);
      });

    await api
      .delete(`/api/v1/transactions/${income.id}`)
      .set('Authorization', authorization)
      .expect(200);
    await api
      .delete(`/api/v1/transactions/${expense.id}`)
      .set('Authorization', authorization)
      .expect(200);
  }, 30_000);
});
