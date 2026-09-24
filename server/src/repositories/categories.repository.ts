import { Injectable } from '@nestjs/common';
import { Prisma, TransactionType } from '@prisma/client';
import { PrismaService } from '../database/prisma.service';
import type { CategoryEntity } from '../entities/category.entity';

const categorySelect = {
  id: true,
  name: true,
  colorHex: true,
  isDefault: true,
  type: true,
  userId: true,
  createdAt: true,
  updatedAt: true,
} satisfies Prisma.CategorySelect;

@Injectable()
export class CategoriesRepository {
  constructor(private readonly prisma: PrismaService) {}

  findVisibleByUser(userId: number): Promise<CategoryEntity[]> {
    return this.prisma.category.findMany({
      where: { OR: [{ isDefault: true, userId: null }, { userId }] },
      select: categorySelect,
      orderBy: [{ isDefault: 'desc' }, { name: 'asc' }],
    });
  }

  findById(id: number) {
    return this.prisma.category.findUnique({ where: { id } });
  }

  findDuplicate(
    userId: number,
    normalizedName: string,
    type: TransactionType,
    excludeId?: number,
  ) {
    return this.prisma.category.findFirst({
      where: {
        ...(excludeId === undefined ? {} : { id: { not: excludeId } }),
        normalizedName,
        type,
        OR: [{ userId }, { isDefault: true, userId: null }],
      },
    });
  }

  async create(
    userId: number,
    name: string,
    normalizedName: string,
    type: TransactionType,
    colorHex: string,
  ): Promise<CategoryEntity | null> {
    try {
      return await this.prisma.category.create({
        data: {
          name,
          normalizedName,
          type,
          colorHex,
          userId,
          isDefault: false,
        },
        select: categorySelect,
      });
    } catch (error: unknown) {
      if (this.isUniqueConflict(error)) return null;
      throw error;
    }
  }

  async update(
    id: number,
    data: {
      name?: string;
      normalizedName?: string;
      type?: TransactionType;
      colorHex?: string;
    },
  ): Promise<CategoryEntity | null> {
    try {
      return await this.prisma.category.update({
        where: { id },
        data,
        select: categorySelect,
      });
    } catch (error: unknown) {
      if (this.isUniqueConflict(error)) return null;
      throw error;
    }
  }

  countTransactions(id: number): Promise<number> {
    return this.prisma.expense.count({ where: { categoryId: id } });
  }

  async removeAndReassign(
    id: number,
    replacementCategoryId: number,
  ): Promise<boolean> {
    try {
      await this.prisma.$transaction(async (transaction) => {
        await transaction.expense.updateMany({
          where: { categoryId: id },
          data: { categoryId: replacementCategoryId },
        });
        const budgets = await transaction.budget.findMany({
          where: { categoryId: id },
          select: { id: true, userId: true, month: true },
        });
        for (const budget of budgets) {
          const replacementBudget = await transaction.budget.findFirst({
            where: {
              userId: budget.userId,
              categoryId: replacementCategoryId,
              month: budget.month,
            },
            select: { id: true },
          });
          if (replacementBudget) {
            await transaction.budget.delete({ where: { id: budget.id } });
          } else {
            await transaction.budget.update({
              where: { id: budget.id },
              data: { categoryId: replacementCategoryId },
            });
          }
        }
        await transaction.category.delete({ where: { id } });
      });
      return true;
    } catch (error: unknown) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        (error.code === 'P2003' || error.code === 'P2025')
      ) {
        return false;
      }
      throw error;
    }
  }

  private isUniqueConflict(error: unknown): boolean {
    return (
      error instanceof Prisma.PrismaClientKnownRequestError &&
      error.code === 'P2002'
    );
  }
}
