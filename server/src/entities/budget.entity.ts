import type { Prisma } from '@prisma/client';

export interface BudgetEntity {
  id: number;
  userId: number;
  categoryId: number;
  amount: Prisma.Decimal;
  month: Date;
  category: {
    userId: number | null;
    isDefault: boolean;
  };
  createdAt: Date;
  updatedAt: Date;
}
