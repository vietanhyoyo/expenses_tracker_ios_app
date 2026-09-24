import { HttpStatus, Injectable } from '@nestjs/common';
import { ErrorCode } from '../common/constants/error-codes.constant';
import { ApiException } from '../common/exceptions/api.exception';
import type { ServiceResponse } from '../common/interfaces/api-response.interface';
import type { CreateBudgetDto } from '../dto/create-budget.dto';
import type { UpdateBudgetDto } from '../dto/update-budget.dto';
import type { BudgetEntity } from '../entities/budget.entity';
import { BudgetsRepository } from '../repositories/budgets.repository';

@Injectable()
export class BudgetsService {
  constructor(private readonly budgetsRepository: BudgetsRepository) {}

  async findAll(userId: number): Promise<ServiceResponse<BudgetEntity[]>> {
    const budgets = await this.budgetsRepository.findAllByUser(userId);
    return { message: 'Budgets retrieved successfully', data: budgets };
  }

  async create(
    userId: number,
    dto: CreateBudgetDto,
  ): Promise<ServiceResponse<BudgetEntity>> {
    const month = this.parseMonth(dto.month);
    await this.assertExpenseCategory(userId, dto.categoryId);
    await this.assertNotDuplicate(userId, dto.categoryId, month);

    const budget = await this.budgetsRepository.create(userId, {
      categoryId: dto.categoryId,
      amount: dto.amount,
      month,
    });
    if (!budget) this.throwDuplicate();
    return { message: 'Budget created successfully', data: budget };
  }

  async update(
    userId: number,
    id: number,
    dto: UpdateBudgetDto,
  ): Promise<ServiceResponse<BudgetEntity>> {
    const current = await this.findOwned(userId, id);
    const categoryId = dto.categoryId ?? current.categoryId;
    const month = dto.month === undefined
      ? current.month
      : this.parseMonth(dto.month);
    await this.assertExpenseCategory(userId, categoryId);
    await this.assertNotDuplicate(userId, categoryId, month, id);

    const budget = await this.budgetsRepository.update(id, {
      ...(dto.categoryId === undefined ? {} : { categoryId }),
      ...(dto.amount === undefined ? {} : { amount: dto.amount }),
      ...(dto.month === undefined ? {} : { month }),
    });
    if (!budget) this.throwDuplicate();
    return { message: 'Budget updated successfully', data: budget };
  }

  async remove(userId: number, id: number): Promise<ServiceResponse<null>> {
    await this.findOwned(userId, id);
    if (!(await this.budgetsRepository.remove(userId, id))) {
      throw new ApiException(
        ErrorCode.BUDGET_NOT_FOUND,
        'Budget not found',
        HttpStatus.NOT_FOUND,
      );
    }
    return { message: 'Budget deleted successfully', data: null };
  }

  private async findOwned(userId: number, id: number): Promise<BudgetEntity> {
    const budget = await this.budgetsRepository.findByIdForUser(userId, id);
    if (!budget) {
      throw new ApiException(
        ErrorCode.BUDGET_NOT_FOUND,
        'Budget not found',
        HttpStatus.NOT_FOUND,
      );
    }
    return budget;
  }

  private async assertExpenseCategory(userId: number, categoryId: number): Promise<void> {
    if (
      !(await this.budgetsRepository.isExpenseCategoryAccessible(userId, categoryId))
    ) {
      throw new ApiException(
        ErrorCode.CATEGORY_NOT_FOUND,
        'Budget category must be an accessible expense category',
        HttpStatus.NOT_FOUND,
      );
    }
  }

  private async assertNotDuplicate(
    userId: number,
    categoryId: number,
    month: Date,
    excludeId?: number,
  ): Promise<void> {
    if (await this.budgetsRepository.findDuplicate(userId, categoryId, month, excludeId)) {
      this.throwDuplicate();
    }
  }

  private parseMonth(value: string): Date {
    const [year, month, day] = value.split('-').map(Number);
    const parsed = new Date(Date.UTC(year, month - 1, day));
    if (
      !Number.isInteger(year) ||
      !Number.isInteger(month) ||
      !Number.isInteger(day) ||
      parsed.getUTCFullYear() !== year ||
      parsed.getUTCMonth() !== month - 1 ||
      parsed.getUTCDate() !== day
    ) {
      throw new ApiException(
        ErrorCode.VALIDATION_ERROR,
        'Invalid budget month',
        HttpStatus.BAD_REQUEST,
      );
    }
    return new Date(Date.UTC(year, month - 1, 1));
  }

  private throwDuplicate(): never {
    throw new ApiException(
      ErrorCode.BUDGET_ALREADY_EXISTS,
      'A budget already exists for this category and month',
      HttpStatus.CONFLICT,
    );
  }
}
