import { Injectable } from '@nestjs/common';
import { Prisma, AccountType } from '@prisma/client';
import { PrismaService } from '../database/prisma.service';
import type { AccountEntity } from '../entities/account.entity';

const accountSelect = {
  id: true,
  userId: true,
  name: true,
  type: true,
  initialBalance: true,
  isDefault: true,
  createdAt: true,
  updatedAt: true,
} satisfies Prisma.AccountSelect;

@Injectable()
export class AccountsRepository {
  constructor(private readonly prisma: PrismaService) {}

  findAllByUser(userId: number): Promise<AccountEntity[]> {
    return this.prisma.account.findMany({
      where: { userId },
      select: accountSelect,
      orderBy: [{ isDefault: 'desc' }, { name: 'asc' }],
    });
  }

  findByIdForUser(userId: number, id: number): Promise<AccountEntity | null> {
    return this.prisma.account.findFirst({
      where: { id, userId },
      select: accountSelect,
    });
  }

  findByName(userId: number, name: string, excludeId?: number) {
    return this.prisma.account.findFirst({
      where: {
        userId,
        name,
        ...(excludeId === undefined ? {} : { id: { not: excludeId } }),
      },
      select: { id: true },
    });
  }

  async create(
    userId: number,
    data: {
      name: string;
      type: AccountType;
      initialBalance: number;
      isDefault?: boolean;
    },
  ): Promise<AccountEntity | null> {
    try {
      return await this.prisma.account.create({
        data: { userId, ...data },
        select: accountSelect,
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
      type?: AccountType;
      initialBalance?: number;
    },
  ): Promise<AccountEntity | null> {
    try {
      return await this.prisma.account.update({
        where: { id },
        data,
        select: accountSelect,
      });
    } catch (error: unknown) {
      if (this.isUniqueConflict(error)) return null;
      throw error;
    }
  }

  async remove(userId: number, id: number): Promise<boolean> {
    const result = await this.prisma.account.deleteMany({
      where: { id, userId, isDefault: false },
    });
    return result.count > 0;
  }

  private isUniqueConflict(error: unknown): boolean {
    return (
      error instanceof Prisma.PrismaClientKnownRequestError &&
      error.code === 'P2002'
    );
  }
}
