import type { Prisma } from '@prisma/client';

export interface DashboardSummaryEntity {
  month: string;
  totalBalance: Prisma.Decimal;
  monthlyIncome: Prisma.Decimal;
  monthlyExpense: Prisma.Decimal;
  monthlyBalance: Prisma.Decimal;
}
