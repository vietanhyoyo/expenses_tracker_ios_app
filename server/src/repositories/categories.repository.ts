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

  countExpenses(id: number): Promise<number> {
    return this.prisma.expense.count({ where: { categoryId: id } });
  }

  async remove(id: number): Promise<boolean> {
    try {
      await this.prisma.category.delete({ where: { id } });
      return true;
    } catch (error: unknown) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2003'
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
