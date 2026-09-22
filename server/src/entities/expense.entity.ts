import type { Prisma } from '@prisma/client';

export interface ExpenseCategoryEntity {
  id: number;
  name: string;
  isDefault: boolean;
}

export interface ExpenseEntity {
  id: number;
  userId: number;
  categoryId: number;
  title: string;
  amount: Prisma.Decimal;
  expenseDate: Date;
  location: string | null;
  notes: string | null;
  createdAt: Date;
  updatedAt: Date;
  category: ExpenseCategoryEntity;
}

export interface PaginatedExpensesEntity {
  items: ExpenseEntity[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
}
