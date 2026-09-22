import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../database/prisma.service';
import type { ExpenseEntity } from '../entities/expense.entity';

const expenseInclude = {
  category: { select: { id: true, name: true, isDefault: true } },
} satisfies Prisma.ExpenseInclude;

interface CreateExpenseRecord {
  userId: number;
  categoryId: number;
  title: string;
  amount: number;
  expenseDate: Date;
  location: string | null;
  notes: string | null;
}

interface ExpenseFilters {
  userId: number;
  categoryId?: number;
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

  findOwned(userId: number, id: number): Promise<ExpenseEntity | null> {
    return this.prisma.expense.findFirst({
      where: { id, userId },
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
  ): Promise<boolean> {
    const category = await this.prisma.category.findFirst({
      where: {
        id: categoryId,
        OR: [{ isDefault: true, userId: null }, { userId }],
      },
      select: { id: true },
    });
    return category !== null;
  }
}
