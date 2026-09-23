import { HttpStatus, Injectable } from '@nestjs/common';
import { AccountType } from '@prisma/client';
import { ErrorCode } from '../common/constants/error-codes.constant';
import { ApiException } from '../common/exceptions/api.exception';
import type { ServiceResponse } from '../common/interfaces/api-response.interface';
import { cleanText } from '../common/utils/normalize.util';
import type { CreateAccountDto } from '../dto/create-account.dto';
import type { UpdateAccountDto } from '../dto/update-account.dto';
import type { AccountEntity } from '../entities/account.entity';
import { AccountsRepository } from '../repositories/accounts.repository';

const defaultAccounts: Array<{
  name: string;
  type: AccountType;
}> = [
  { name: 'Tiền mặt', type: AccountType.cash },
  { name: 'Ví điện tử', type: AccountType.ewallet },
  { name: 'Ngân hàng', type: AccountType.bank },
];

@Injectable()
export class AccountsService {
  constructor(private readonly accountsRepository: AccountsRepository) {}

  async findAll(userId: number): Promise<ServiceResponse<AccountEntity[]>> {
    await this.ensureDefaults(userId);
    const accounts = await this.accountsRepository.findAllByUser(userId);
    return { message: 'Accounts retrieved successfully', data: accounts };
  }

  async create(
    userId: number,
    dto: CreateAccountDto,
  ): Promise<ServiceResponse<AccountEntity>> {
    const name = cleanText(dto.name).replace(/\s+/g, ' ');
    await this.assertNameAvailable(userId, name);
    const account = await this.accountsRepository.create(userId, {
      name,
      type: dto.type,
      initialBalance: dto.initialBalance ?? 0,
    });
    if (!account) this.throwDuplicate();
    return { message: 'Account created successfully', data: account };
  }

  async update(
    userId: number,
    id: number,
    dto: UpdateAccountDto,
  ): Promise<ServiceResponse<AccountEntity>> {
    await this.assertOwned(userId, id);
    const data: {
      name?: string;
      type?: AccountType;
      initialBalance?: number;
    } = {};
    if (dto.name !== undefined) {
      const name = cleanText(dto.name).replace(/\s+/g, ' ');
      await this.assertNameAvailable(userId, name, id);
      data.name = name;
    }
    if (dto.type !== undefined) data.type = dto.type;
    if (dto.initialBalance !== undefined) {
      data.initialBalance = dto.initialBalance;
    }
    const account = await this.accountsRepository.update(id, data);
    if (!account) this.throwDuplicate();
    return { message: 'Account updated successfully', data: account };
  }

  async remove(userId: number, id: number): Promise<ServiceResponse<null>> {
    await this.assertOwned(userId, id);
    if (!(await this.accountsRepository.remove(userId, id))) {
      throw new ApiException(
        ErrorCode.ACCOUNT_NOT_EDITABLE,
        'Default accounts cannot be deleted',
        HttpStatus.FORBIDDEN,
      );
    }
    return { message: 'Account deleted successfully', data: null };
  }

  private async ensureDefaults(userId: number): Promise<void> {
    const existing = await this.accountsRepository.findAllByUser(userId);
    for (const account of defaultAccounts) {
      if (!existing.some((item) => item.type === account.type)) {
        await this.accountsRepository.create(userId, {
          ...account,
          initialBalance: 0,
          isDefault: true,
        });
      }
    }
  }

  private async assertOwned(
    userId: number,
    id: number,
  ): Promise<AccountEntity> {
    const account = await this.accountsRepository.findByIdForUser(userId, id);
    if (!account) {
      throw new ApiException(
        ErrorCode.ACCOUNT_NOT_FOUND,
        'Account not found',
        HttpStatus.NOT_FOUND,
      );
    }
    return account;
  }

  private async assertNameAvailable(
    userId: number,
    name: string,
    excludeId?: number,
  ): Promise<void> {
    if (await this.accountsRepository.findByName(userId, name, excludeId)) {
      this.throwDuplicate();
    }
  }

  private throwDuplicate(): never {
    throw new ApiException(
      ErrorCode.ACCOUNT_ALREADY_EXISTS,
      'Account already exists',
      HttpStatus.CONFLICT,
    );
  }
}
