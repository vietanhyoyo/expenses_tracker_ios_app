import { HttpStatus, Injectable } from '@nestjs/common';
import { ErrorCode } from '../common/constants/error-codes.constant';
import { ApiException } from '../common/exceptions/api.exception';
import type { ServiceResponse } from '../common/interfaces/api-response.interface';
import {
  cleanText,
  normalizeCategoryName,
} from '../common/utils/normalize.util';
import type { CreateCategoryDto } from '../dto/create-category.dto';
import type { UpdateCategoryDto } from '../dto/update-category.dto';
import type { CategoryEntity } from '../entities/category.entity';
import { CategoriesRepository } from '../repositories/categories.repository';

@Injectable()
export class CategoriesService {
  constructor(private readonly categoriesRepository: CategoriesRepository) {}

  async findAll(userId: number): Promise<ServiceResponse<CategoryEntity[]>> {
    const categories =
      await this.categoriesRepository.findVisibleByUser(userId);
    return { message: 'Categories retrieved successfully', data: categories };
  }

  async create(
    userId: number,
    dto: CreateCategoryDto,
  ): Promise<ServiceResponse<CategoryEntity>> {
    const name = cleanText(dto.name).replace(/\s+/g, ' ');
    const normalizedName = normalizeCategoryName(name);
    const type = dto.type ?? 'expense';
    const duplicate = await this.categoriesRepository.findDuplicate(
      userId,
      normalizedName,
      type,
    );
    if (duplicate) this.throwDuplicate();

    const category = await this.categoriesRepository.create(
      userId,
      name,
      normalizedName,
      type,
    );
    if (!category) this.throwDuplicate();
    return { message: 'Category created successfully', data: category };
  }

  async update(
    userId: number,
    id: number,
    dto: UpdateCategoryDto,
  ): Promise<ServiceResponse<CategoryEntity>> {
    const current = await this.assertEditable(userId, id);
    const targetType = dto.type ?? current.type;
    const data: {
      name?: string;
      normalizedName?: string;
      type?: 'income' | 'expense';
    } = {};
    if (dto.name !== undefined) {
      const name = cleanText(dto.name).replace(/\s+/g, ' ');
      const normalizedName = normalizeCategoryName(name);
      const duplicate = await this.categoriesRepository.findDuplicate(
        userId,
        normalizedName,
        targetType,
        id,
      );
      if (duplicate) this.throwDuplicate();
      data.name = name;
      data.normalizedName = normalizedName;
    }
    if (dto.type !== undefined && dto.type !== current.type) {
      if ((await this.categoriesRepository.countExpenses(id)) > 0) {
        this.throwInUse();
      }
      data.type = dto.type;
    }

    const category = await this.categoriesRepository.update(id, data);
    if (!category) this.throwDuplicate();
    return { message: 'Category updated successfully', data: category };
  }

  async remove(userId: number, id: number): Promise<ServiceResponse<null>> {
    await this.assertEditable(userId, id);
    if ((await this.categoriesRepository.countExpenses(id)) > 0) {
      this.throwInUse();
    }
    if (!(await this.categoriesRepository.remove(id))) this.throwInUse();
    return { message: 'Category deleted successfully', data: null };
  }

  private async assertEditable(userId: number, id: number) {
    const category = await this.categoriesRepository.findById(id);
    if (!category || (category.userId !== null && category.userId !== userId)) {
      throw new ApiException(
        ErrorCode.CATEGORY_NOT_FOUND,
        'Category not found',
        HttpStatus.NOT_FOUND,
      );
    }
    if (category.isDefault || category.userId === null) {
      throw new ApiException(
        ErrorCode.CATEGORY_NOT_EDITABLE,
        'Default categories cannot be modified',
        HttpStatus.FORBIDDEN,
      );
    }
    return category;
  }

  private throwDuplicate(): never {
    throw new ApiException(
      ErrorCode.CATEGORY_ALREADY_EXISTS,
      'Category already exists',
      HttpStatus.CONFLICT,
    );
  }

  private throwInUse(): never {
    throw new ApiException(
      ErrorCode.CATEGORY_IN_USE,
      'Category is currently used by one or more expenses',
      HttpStatus.CONFLICT,
    );
  }
}
