import type { Prisma, TransactionType } from '@prisma/client';

export interface TransactionCategoryEntity {
  id: number;
  name: string;
  isDefault: boolean;
  type: TransactionType;
}

export interface TransactionEntity {
  id: number;
  userId: number;
  categoryId: number;
  type: TransactionType;
  title: string;
  amount: Prisma.Decimal;
  transactionDate: Date;
  notes: string | null;
  createdAt: Date;
  updatedAt: Date;
  category: TransactionCategoryEntity;
}

export interface PaginatedTransactionsEntity {
  items: TransactionEntity[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
}
