import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../database/prisma.service';
import type { BudgetEntity } from '../entities/budget.entity';

const budgetSelect = {
  id: true,
  userId: true,
  categoryId: true,
  amount: true,
  month: true,
  category: { select: { userId: true, isDefault: true } },
  createdAt: true,
  updatedAt: true,
} satisfies Prisma.BudgetSelect;

@Injectable()
export class BudgetsRepository {
  constructor(private readonly prisma: PrismaService) {}

  findAllByUser(userId: number): Promise<BudgetEntity[]> {
    return this.prisma.budget.findMany({
      where: { userId },
      select: budgetSelect,
      orderBy: [{ month: 'desc' }, { categoryId: 'asc' }],
    });
  }

  findByIdForUser(userId: number, id: number): Promise<BudgetEntity | null> {
    return this.prisma.budget.findFirst({
      where: { id, userId },
      select: budgetSelect,
    });
  }

  findDuplicate(
    userId: number,
    categoryId: number,
    month: Date,
    excludeId?: number,
  ): Promise<BudgetEntity | null> {
    return this.prisma.budget.findFirst({
      where: {
        userId,
        categoryId,
        month,
        ...(excludeId === undefined ? {} : { id: { not: excludeId } }),
      },
      select: budgetSelect,
    });
  }

  async create(
    userId: number,
    data: { categoryId: number; amount: number; month: Date },
  ): Promise<BudgetEntity | null> {
    try {
      return await this.prisma.budget.create({
        data: {
          userId,
          categoryId: data.categoryId,
          amount: new Prisma.Decimal(data.amount),
          month: data.month,
        },
        select: budgetSelect,
      });
    } catch (error: unknown) {
      if (this.isUniqueConflict(error)) return null;
      throw error;
    }
  }

  async update(
    id: number,
    data: { categoryId?: number; amount?: number; month?: Date },
  ): Promise<BudgetEntity | null> {
    try {
      return await this.prisma.budget.update({
        where: { id },
        data: {
          ...(data.categoryId === undefined ? {} : { categoryId: data.categoryId }),
          ...(data.amount === undefined
            ? {}
            : { amount: new Prisma.Decimal(data.amount) }),
          ...(data.month === undefined ? {} : { month: data.month }),
        },
        select: budgetSelect,
      });
    } catch (error: unknown) {
      if (this.isUniqueConflict(error)) return null;
      throw error;
    }
  }

  async remove(userId: number, id: number): Promise<boolean> {
    const result = await this.prisma.budget.deleteMany({
      where: { id, userId },
    });
    return result.count > 0;
  }

  isExpenseCategoryAccessible(userId: number, categoryId: number): Promise<boolean> {
    return this.prisma.category
      .findFirst({
        where: {
          id: categoryId,
          type: 'expense',
          OR: [{ isDefault: true, userId: null }, { userId }],
        },
        select: { id: true },
      })
      .then((category) => category !== null);
  }

  private isUniqueConflict(error: unknown): boolean {
    return (
      error instanceof Prisma.PrismaClientKnownRequestError &&
      error.code === 'P2002'
    );
  }
}
