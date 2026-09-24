import type { Prisma } from '@prisma/client';

export interface DashboardSummaryEntity {
  month: string;
  period: 'week' | 'month' | 'year';
  from: string;
  to: string;
  totalBalance: Prisma.Decimal;
  monthlyIncome: Prisma.Decimal;
  monthlyExpense: Prisma.Decimal;
  monthlyBalance: Prisma.Decimal;
}
