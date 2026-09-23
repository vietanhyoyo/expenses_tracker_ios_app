import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../database/prisma.service';

@Injectable()
export class DashboardRepository {
  constructor(private readonly prisma: PrismaService) {}

  async summary(userId: number, from: Date, to: Date) {
    const [totalIncome, totalExpense, monthlyIncome, monthlyExpense] =
      await Promise.all([
        this.sum(userId, 'income'),
        this.sum(userId, 'expense'),
        this.sum(userId, 'income', from, to),
        this.sum(userId, 'expense', from, to),
      ]);
    return { totalIncome, totalExpense, monthlyIncome, monthlyExpense };
  }

  private async sum(
    userId: number,
    type: 'income' | 'expense',
    from?: Date,
    to?: Date,
  ): Promise<Prisma.Decimal> {
    const result = await this.prisma.expense.aggregate({
      where: {
        userId,
        type,
        ...(from && to ? { expenseDate: { gte: from, lt: to } } : {}),
      },
      _sum: { amount: true },
    });
    return result._sum.amount ?? new Prisma.Decimal(0);
  }
}
