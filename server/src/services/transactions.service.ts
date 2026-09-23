import { HttpStatus, Injectable } from '@nestjs/common';
import { Prisma, type TransactionType } from '@prisma/client';
import { ErrorCode } from '../common/constants/error-codes.constant';
import { ApiException } from '../common/exceptions/api.exception';
import type { ServiceResponse } from '../common/interfaces/api-response.interface';
import { cleanText } from '../common/utils/normalize.util';
import type { CreateTransactionDto } from '../dto/create-transaction.dto';
import type { QueryTransactionTrendDto } from '../dto/query-transaction-trend.dto';
import type { QueryTransactionsDto } from '../dto/query-transactions.dto';
import type { UpdateTransactionDto } from '../dto/update-transaction.dto';
import type { ExpenseEntity } from '../entities/expense.entity';
import type {
  PaginatedTransactionsEntity,
  TransactionEntity,
} from '../entities/transaction.entity';
import type { TransactionTrendEntity } from '../entities/transaction-trend.entity';
import { ExpensesRepository } from '../repositories/expenses.repository';

@Injectable()
export class TransactionsService {
  constructor(private readonly repository: ExpensesRepository) {}

  async create(
    userId: number,
    dto: CreateTransactionDto,
  ): Promise<ServiceResponse<TransactionEntity>> {
    await this.assertCategoryAccessible(userId, dto.categoryId, dto.type);
    const transaction = await this.repository.create({
      userId,
      categoryId: dto.categoryId,
      type: dto.type,
      title: cleanText(dto.title),
      amount: dto.amount,
      expenseDate: new Date(dto.transactionDate),
      location: null,
      notes: this.cleanOptional(dto.notes),
    });
    return {
      message: 'Transaction created successfully',
      data: this.toEntity(transaction),
    };
  }

  async findAll(
    userId: number,
    query: QueryTransactionsDto,
  ): Promise<ServiceResponse<PaginatedTransactionsEntity>> {
    if (query.from && query.to && new Date(query.from) > new Date(query.to)) {
      throw new ApiException(
        ErrorCode.VALIDATION_ERROR,
        'Invalid date range',
        HttpStatus.BAD_REQUEST,
        [{ field: 'from', message: 'from must be before or equal to to' }],
      );
    }
    const { items, total } = await this.repository.findPaginated({
      userId,
      type: query.type,
      categoryId: query.categoryId,
      from: query.from ? new Date(query.from) : undefined,
      to: query.to ? this.endOfInputDate(query.to) : undefined,
      sortBy: query.sortBy === 'transactionDate' ? 'expenseDate' : query.sortBy,
      sortOrder: query.sortOrder,
      page: query.page,
      limit: query.limit,
    });
    return {
      message: 'Transactions retrieved successfully',
      data: {
        items: items.map((item) => this.toEntity(item)),
        pagination: {
          page: query.page,
          limit: query.limit,
          total,
          totalPages: Math.ceil(total / query.limit),
        },
      },
    };
  }

  async trend(
    userId: number,
    query: QueryTransactionTrendDto,
  ): Promise<ServiceResponse<TransactionTrendEntity>> {
    const anchor = this.parseCalendarDate(query.date);
    const range = this.rangeFor(query.period, anchor);
    const rows = await this.repository.findTransactionAmounts(
      userId,
      query.type,
      range.from,
      range.to,
    );
    const amounts = new Map<string, Prisma.Decimal>();
    for (const row of rows) {
      const key = this.bucketKey(row.expenseDate, range.granularity);
      amounts.set(key, (amounts.get(key) ?? new Prisma.Decimal(0)).plus(row.amount));
    }

    const items: TransactionTrendEntity['items'] = [];
    for (
      let cursor = range.from;
      cursor < range.to;
      cursor = this.nextBucket(cursor, range.granularity)
    ) {
      const date = this.formatCalendarDate(cursor);
      const key = range.granularity === 'month' ? `${date.slice(0, 7)}-01` : date;
      items.push({ date: key, amount: amounts.get(key) ?? new Prisma.Decimal(0) });
    }

    return {
      message: 'Transaction trend retrieved successfully',
      data: {
        type: query.type,
        period: query.period,
        granularity: range.granularity,
        from: this.formatCalendarDate(range.from),
        to: this.formatCalendarDate(range.to),
        items,
      },
    };
  }

  async findOne(
    userId: number,
    id: number,
  ): Promise<ServiceResponse<TransactionEntity>> {
    const transaction = await this.findOwned(userId, id);
    return {
      message: 'Transaction retrieved successfully',
      data: this.toEntity(transaction),
    };
  }

  async update(
    userId: number,
    id: number,
    dto: UpdateTransactionDto,
  ): Promise<ServiceResponse<TransactionEntity>> {
    const current = await this.findOwned(userId, id);
    const targetType = dto.type ?? current.type;
    const targetCategoryId = dto.categoryId ?? current.categoryId;
    if (dto.type !== undefined || dto.categoryId !== undefined) {
      await this.assertCategoryAccessible(userId, targetCategoryId, targetType);
    }
    const updated = await this.repository.update(id, {
      ...(dto.type === undefined ? {} : { type: dto.type }),
      ...(dto.title === undefined ? {} : { title: cleanText(dto.title) }),
      ...(dto.amount === undefined ? {} : { amount: dto.amount }),
      ...(dto.transactionDate === undefined
        ? {}
        : { expenseDate: new Date(dto.transactionDate) }),
      ...(dto.categoryId === undefined ? {} : { categoryId: dto.categoryId }),
      ...(dto.notes === undefined
        ? {}
        : { notes: this.cleanOptional(dto.notes) }),
    });
    return {
      message: 'Transaction updated successfully',
      data: this.toEntity(updated),
    };
  }

  async remove(userId: number, id: number): Promise<ServiceResponse<null>> {
    await this.findOwned(userId, id);
    await this.repository.remove(id);
    return { message: 'Transaction deleted successfully', data: null };
  }

  private async findOwned(userId: number, id: number): Promise<ExpenseEntity> {
    const transaction = await this.repository.findOwned(userId, id);
    if (!transaction) {
      throw new ApiException(
        ErrorCode.TRANSACTION_NOT_FOUND,
        'Transaction not found',
        HttpStatus.NOT_FOUND,
      );
    }
    return transaction;
  }

  private async assertCategoryAccessible(
    userId: number,
    categoryId: number,
    type: TransactionType,
  ): Promise<void> {
    if (
      !(await this.repository.isCategoryAccessible(userId, categoryId, type))
    ) {
      throw new ApiException(
        ErrorCode.CATEGORY_NOT_FOUND,
        'Category not found, inaccessible, or has a different type',
        HttpStatus.NOT_FOUND,
      );
    }
  }

  private toEntity(value: ExpenseEntity): TransactionEntity {
    return {
      id: value.id,
      userId: value.userId,
      categoryId: value.categoryId,
      type: value.type,
      title: value.title,
      amount: value.amount,
      transactionDate: value.expenseDate,
      notes: value.notes,
      createdAt: value.createdAt,
      updatedAt: value.updatedAt,
      category: value.category,
    };
  }

  private cleanOptional(value: string | undefined): string | null {
    if (value === undefined) return null;
    const cleaned = cleanText(value);
    return cleaned.length ? cleaned : null;
  }

  private endOfInputDate(value: string): Date {
    return /^\d{4}-\d{2}-\d{2}$/.test(value)
      ? new Date(`${value}T23:59:59.999Z`)
      : new Date(value);
  }

  private parseCalendarDate(value: string): Date {
    const [year, month, day] = value.split('-').map(Number);
    return new Date(Date.UTC(year, month - 1, day));
  }

  private rangeFor(
    period: QueryTransactionTrendDto['period'],
    anchor: Date,
  ): { from: Date; to: Date; granularity: 'day' | 'month' } {
    if (period === 'year') {
      const from = new Date(Date.UTC(anchor.getUTCFullYear(), 0, 1));
      return {
        from,
        to: new Date(Date.UTC(anchor.getUTCFullYear() + 1, 0, 1)),
        granularity: 'month',
      };
    }
    if (period === 'month') {
      const from = new Date(Date.UTC(anchor.getUTCFullYear(), anchor.getUTCMonth(), 1));
      return {
        from,
        to: new Date(Date.UTC(anchor.getUTCFullYear(), anchor.getUTCMonth() + 1, 1)),
        granularity: 'day',
      };
    }

    const dayOffset = (anchor.getUTCDay() + 6) % 7;
    const from = new Date(
      Date.UTC(anchor.getUTCFullYear(), anchor.getUTCMonth(), anchor.getUTCDate() - dayOffset),
    );
    return {
      from,
      to: new Date(Date.UTC(from.getUTCFullYear(), from.getUTCMonth(), from.getUTCDate() + 7)),
      granularity: 'day',
    };
  }

  private nextBucket(date: Date, granularity: 'day' | 'month'): Date {
    return granularity === 'month'
      ? new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth() + 1, 1))
      : new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate() + 1));
  }

  private bucketKey(date: Date, granularity: 'day' | 'month'): string {
    const value = this.formatCalendarDate(date);
    return granularity === 'month' ? `${value.slice(0, 7)}-01` : value;
  }

  private formatCalendarDate(date: Date): string {
    return date.toISOString().slice(0, 10);
  }
}
