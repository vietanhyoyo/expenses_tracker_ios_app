import { Injectable } from '@nestjs/common';
import { Prisma, TransactionType } from '@prisma/client';
import { PrismaService } from '../database/prisma.service';
import type { ExpenseEntity } from '../entities/expense.entity';

const expenseInclude = {
  category: {
    select: { id: true, name: true, isDefault: true, type: true },
  },
} satisfies Prisma.ExpenseInclude;

interface CreateExpenseRecord {
  userId: number;
  categoryId: number;
  type: TransactionType;
  title: string;
  amount: number;
  expenseDate: Date;
  location: string | null;
  notes: string | null;
}

interface ExpenseFilters {
  userId: number;
  categoryId?: number;
  type?: TransactionType;
  from?: Date;
  to?: Date;
  sortBy: 'expenseDate' | 'amount' | 'createdAt';
  sortOrder: 'asc' | 'desc';
  page: number;
  limit: number;
}

interface UpdateExpenseRecord {
  title?: string;
  amount?: number;
  expenseDate?: Date;
  categoryId?: number;
  type?: TransactionType;
  location?: string | null;
  notes?: string | null;
}

@Injectable()
export class ExpensesRepository {
  constructor(private readonly prisma: PrismaService) {}

  create(data: CreateExpenseRecord): Promise<ExpenseEntity> {
    return this.prisma.expense.create({
      data: { ...data, amount: new Prisma.Decimal(data.amount) },
      include: expenseInclude,
    });
  }

  async findPaginated(
    filters: ExpenseFilters,
  ): Promise<{ items: ExpenseEntity[]; total: number }> {
    const where: Prisma.ExpenseWhereInput = { userId: filters.userId };
    if (filters.categoryId !== undefined) where.categoryId = filters.categoryId;
    if (filters.type !== undefined) where.type = filters.type;
    if (filters.from || filters.to) {
      where.expenseDate = {
        ...(filters.from ? { gte: filters.from } : {}),
        ...(filters.to ? { lte: filters.to } : {}),
      };
    }
    const orderBy: Prisma.ExpenseOrderByWithRelationInput = {
      [filters.sortBy]: filters.sortOrder,
    };
    const [items, total] = await this.prisma.$transaction([
      this.prisma.expense.findMany({
        where,
        include: expenseInclude,
        orderBy: [orderBy, { id: filters.sortOrder }],
        skip: (filters.page - 1) * filters.limit,
        take: filters.limit,
      }),
      this.prisma.expense.count({ where }),
    ]);
    return { items, total };
  }

  findTransactionAmounts(
    userId: number,
    type: TransactionType,
    from: Date,
    to: Date,
  ): Promise<Array<{ expenseDate: Date; amount: Prisma.Decimal }>> {
    return this.prisma.expense.findMany({
      where: {
        userId,
        type,
        expenseDate: { gte: from, lt: to },
      },
      select: { expenseDate: true, amount: true },
      orderBy: { expenseDate: 'asc' },
    });
  }

  findOwned(
    userId: number,
    id: number,
    type?: TransactionType,
  ): Promise<ExpenseEntity | null> {
    return this.prisma.expense.findFirst({
      where: { id, userId, ...(type === undefined ? {} : { type }) },
      include: expenseInclude,
    });
  }

  update(id: number, data: UpdateExpenseRecord): Promise<ExpenseEntity> {
    return this.prisma.expense.update({
      where: { id },
      data: {
        ...data,
        ...(data.amount === undefined
          ? {}
          : { amount: new Prisma.Decimal(data.amount) }),
      },
      include: expenseInclude,
    });
  }

  async remove(id: number): Promise<void> {
    await this.prisma.expense.delete({ where: { id } });
  }

  async isCategoryAccessible(
    userId: number,
    categoryId: number,
    type?: TransactionType,
  ): Promise<boolean> {
    const category = await this.prisma.category.findFirst({
      where: {
        id: categoryId,
        OR: [{ isDefault: true, userId: null }, { userId }],
        ...(type === undefined ? {} : { type }),
      },
      select: { id: true },
    });
    return category !== null;
  }
}
