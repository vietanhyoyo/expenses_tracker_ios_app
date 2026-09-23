import type { TransactionType } from '@prisma/client';

export interface CategoryEntity {
  id: number;
  name: string;
  isDefault: boolean;
  type: TransactionType;
  userId: number | null;
  createdAt: Date;
  updatedAt: Date;
}
