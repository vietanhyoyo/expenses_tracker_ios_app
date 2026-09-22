import { HttpStatus, Injectable } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ErrorCode } from '../constants/error-codes.constant';
import { ApiException } from '../exceptions/api.exception';
import type { AuthUser } from '../interfaces/auth-user.interface';

@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {
  handleRequest<TUser = AuthUser>(
    error: unknown,
    user: TUser | false,
    info?: Error,
  ): TUser {
    if (error || !user) {
      const expired = info?.name === 'TokenExpiredError';
      throw new ApiException(
        expired
          ? ErrorCode.ACCESS_TOKEN_EXPIRED
          : ErrorCode.ACCESS_TOKEN_INVALID,
        expired ? 'Access token has expired' : 'Access token is invalid',
        HttpStatus.UNAUTHORIZED,
      );
    }
    return user;
  }
}
