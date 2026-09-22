import { HttpStatus, Injectable } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ErrorCode } from '../constants/error-codes.constant';
import { ApiException } from '../exceptions/api.exception';
import type { RefreshAuthUser } from '../interfaces/auth-user.interface';

@Injectable()
export class RefreshTokenGuard extends AuthGuard('jwt-refresh') {
  handleRequest<TUser = RefreshAuthUser>(
    error: unknown,
    user: TUser | false,
    info?: Error,
  ): TUser {
    if (error || !user) {
      const expired = info?.name === 'TokenExpiredError';
      throw new ApiException(
        expired
          ? ErrorCode.REFRESH_TOKEN_EXPIRED
          : ErrorCode.REFRESH_TOKEN_INVALID,
        expired ? 'Refresh token has expired' : 'Refresh token is invalid',
        HttpStatus.UNAUTHORIZED,
      );
    }
    return user;
  }
}
