import { HttpStatus, Injectable } from '@nestjs/common';
import { ErrorCode } from '../common/constants/error-codes.constant';
import { ApiException } from '../common/exceptions/api.exception';
import type { ServiceResponse } from '../common/interfaces/api-response.interface';
import type { UserEntity } from '../entities/user.entity';
import { UsersRepository } from '../repositories/users.repository';

@Injectable()
export class UsersService {
  constructor(private readonly usersRepository: UsersRepository) {}

  async findMe(userId: number): Promise<ServiceResponse<UserEntity>> {
    const user = await this.usersRepository.findPublicById(userId);
    if (!user) {
      throw new ApiException(
        ErrorCode.UNAUTHORIZED,
        'User no longer exists',
        HttpStatus.UNAUTHORIZED,
      );
    }
    return { message: 'User retrieved successfully', data: user };
  }
}
