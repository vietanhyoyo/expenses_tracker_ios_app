import { HttpStatus, Injectable } from '@nestjs/common';
import { ErrorCode } from '../common/constants/error-codes.constant';
import { ApiException } from '../common/exceptions/api.exception';
import type { ServiceResponse } from '../common/interfaces/api-response.interface';
import { cleanText } from '../common/utils/normalize.util';
import type { CreateExpenseDto } from '../dto/create-expense.dto';
import type { QueryExpensesDto } from '../dto/query-expenses.dto';
import type { UpdateExpenseDto } from '../dto/update-expense.dto';
import type {
  ExpenseEntity,
  PaginatedExpensesEntity,
} from '../entities/expense.entity';
import { ExpensesRepository } from '../repositories/expenses.repository';

@Injectable()
export class ExpensesService {
  constructor(private readonly expensesRepository: ExpensesRepository) {}

  async create(
    userId: number,
    dto: CreateExpenseDto,
  ): Promise<ServiceResponse<ExpenseEntity>> {
    await this.assertCategoryAccessible(userId, dto.categoryId);
    const expense = await this.expensesRepository.create({
      userId,
      categoryId: dto.categoryId,
      title: cleanText(dto.title),
      amount: dto.amount,
      expenseDate: new Date(dto.expenseDate),
      location: this.cleanOptional(dto.location),
      notes: this.cleanOptional(dto.notes),
    });
    return { message: 'Expense created successfully', data: expense };
  }

  async findAll(
    userId: number,
    query: QueryExpensesDto,
  ): Promise<ServiceResponse<PaginatedExpensesEntity>> {
    if (query.from && query.to && new Date(query.from) > new Date(query.to)) {
      throw new ApiException(
        ErrorCode.VALIDATION_ERROR,
        'Invalid date range',
        HttpStatus.BAD_REQUEST,
        [{ field: 'from', message: 'from must be before or equal to to' }],
      );
    }

    const { items, total } = await this.expensesRepository.findPaginated({
      userId,
      categoryId: query.categoryId,
      from: query.from ? new Date(query.from) : undefined,
      to: query.to ? this.endOfInputDate(query.to) : undefined,
      sortBy: query.sortBy,
      sortOrder: query.sortOrder,
      page: query.page,
      limit: query.limit,
    });
    return {
      message: 'Expenses retrieved successfully',
      data: {
        items,
        pagination: {
          page: query.page,
          limit: query.limit,
          total,
          totalPages: Math.ceil(total / query.limit),
        },
      },
    };
  }

  async findOne(
    userId: number,
    id: number,
  ): Promise<ServiceResponse<ExpenseEntity>> {
    const expense = await this.findOwnedExpense(userId, id);
    return { message: 'Expense retrieved successfully', data: expense };
  }

  async update(
    userId: number,
    id: number,
    dto: UpdateExpenseDto,
  ): Promise<ServiceResponse<ExpenseEntity>> {
    await this.findOwnedExpense(userId, id);
    if (dto.categoryId !== undefined) {
      await this.assertCategoryAccessible(userId, dto.categoryId);
    }
    const updated = await this.expensesRepository.update(id, {
      ...(dto.title === undefined ? {} : { title: cleanText(dto.title) }),
      ...(dto.amount === undefined ? {} : { amount: dto.amount }),
      ...(dto.expenseDate === undefined
        ? {}
        : { expenseDate: new Date(dto.expenseDate) }),
      ...(dto.categoryId === undefined ? {} : { categoryId: dto.categoryId }),
      ...(dto.location === undefined
        ? {}
        : { location: this.cleanOptional(dto.location) }),
      ...(dto.notes === undefined
        ? {}
        : { notes: this.cleanOptional(dto.notes) }),
    });
    return { message: 'Expense updated successfully', data: updated };
  }

  async remove(userId: number, id: number): Promise<ServiceResponse<null>> {
    await this.findOwnedExpense(userId, id);
    await this.expensesRepository.remove(id);
    return { message: 'Expense deleted successfully', data: null };
  }

  private async findOwnedExpense(
    userId: number,
    id: number,
  ): Promise<ExpenseEntity> {
    const expense = await this.expensesRepository.findOwned(userId, id);
    if (!expense) {
      throw new ApiException(
        ErrorCode.EXPENSE_NOT_FOUND,
        'Expense not found',
        HttpStatus.NOT_FOUND,
      );
    }
    return expense;
  }

  private async assertCategoryAccessible(
    userId: number,
    categoryId: number,
  ): Promise<void> {
    if (
      !(await this.expensesRepository.isCategoryAccessible(userId, categoryId))
    ) {
      throw new ApiException(
        ErrorCode.CATEGORY_NOT_FOUND,
        'Category not found or is not accessible',
        HttpStatus.NOT_FOUND,
      );
    }
  }

  private cleanOptional(value: string | undefined): string | null {
    if (value === undefined) return null;
    const cleaned = cleanText(value);
    return cleaned.length ? cleaned : null;
  }

  private endOfInputDate(value: string): Date {
    if (/^\d{4}-\d{2}-\d{2}$/.test(value)) {
      return new Date(`${value}T23:59:59.999Z`);
    }
    return new Date(value);
  }
}
