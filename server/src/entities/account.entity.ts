import type { Prisma, AccountType } from '@prisma/client';

export interface AccountEntity {
  id: number;
  userId: number;
  name: string;
  type: AccountType;
  initialBalance: Prisma.Decimal;
  isDefault: boolean;
  createdAt: Date;
  updatedAt: Date;
}
