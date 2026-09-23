import type { Prisma } from '@prisma/client';

export interface TransactionTrendItemEntity {
  date: string;
  amount: Prisma.Decimal;
}

export interface TransactionTrendEntity {
  type: 'income' | 'expense';
  period: 'week' | 'month' | 'year';
  granularity: 'day' | 'month';
  from: string;
  to: string;
  items: TransactionTrendItemEntity[];
}
