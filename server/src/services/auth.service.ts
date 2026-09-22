import { createHash, randomUUID } from 'node:crypto';
import { HttpStatus, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import type { SignOptions } from 'jsonwebtoken';
import { ErrorCode } from '../common/constants/error-codes.constant';
import { ApiException } from '../common/exceptions/api.exception';
import type {
  AuthUser,
  RefreshAuthUser,
} from '../common/interfaces/auth-user.interface';
import type { ServiceResponse } from '../common/interfaces/api-response.interface';
import { normalizeEmail } from '../common/utils/normalize.util';
import type { LoginDto } from '../dto/login.dto';
import type { RefreshTokenDto } from '../dto/refresh-token.dto';
import type { RegisterDto } from '../dto/register.dto';
import type { AuthResult, TokenPair } from '../entities/auth.entity';
import { AuthRepository } from '../repositories/auth.repository';

interface JwtExpirationPayload {
  exp?: number;
}

@Injectable()
export class AuthService {
  constructor(
    private readonly authRepository: AuthRepository,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
  ) {}

  async register(dto: RegisterDto): Promise<ServiceResponse<AuthResult>> {
    const email = normalizeEmail(dto.email);
    const existing = await this.authRepository.findUserByEmail(email);
    if (existing) {
      throw new ApiException(
        ErrorCode.EMAIL_ALREADY_EXISTS,
        'Email already exists',
        HttpStatus.CONFLICT,
      );
    }

    const saltRounds = Number(
      this.config.get<string>('BCRYPT_SALT_ROUNDS', '12'),
    );
    const passwordHash = await bcrypt.hash(dto.password, saltRounds);
    const user = await this.authRepository.createUser(email, passwordHash);
    if (!user) {
      throw new ApiException(
        ErrorCode.EMAIL_ALREADY_EXISTS,
        'Email already exists',
        HttpStatus.CONFLICT,
      );
    }

    const tokens = await this.issueAndStoreTokens(user.id, user.email);
    return {
      message: 'User registered successfully',
      data: { user, ...tokens },
    };
  }

  async login(dto: LoginDto): Promise<ServiceResponse<AuthResult>> {
    const email = normalizeEmail(dto.email);
    const user = await this.authRepository.findUserByEmail(email);
    const valid = user
      ? await bcrypt.compare(dto.password, user.passwordHash)
      : false;
    if (!user || !valid) {
      throw new ApiException(
        ErrorCode.INVALID_CREDENTIALS,
        'Email or password is incorrect',
        HttpStatus.UNAUTHORIZED,
      );
    }

    const tokens = await this.issueAndStoreTokens(user.id, user.email);
    return {
      message: 'Login successful',
      data: {
        user: { id: user.id, email: user.email, createdAt: user.createdAt },
        ...tokens,
      },
    };
  }

  async refresh(user: RefreshAuthUser): Promise<ServiceResponse<TokenPair>> {
    const now = new Date();
    const tokenHash = this.hashToken(user.refreshToken);
    const stored = await this.authRepository.findRefreshToken(tokenHash);
    if (!stored || stored.userId !== user.id) {
      throw new ApiException(
        ErrorCode.REFRESH_TOKEN_INVALID,
        'Refresh token is invalid',
        HttpStatus.UNAUTHORIZED,
      );
    }
    if (stored.revokedAt) {
      throw new ApiException(
        ErrorCode.REFRESH_TOKEN_REVOKED,
        'Refresh token has been revoked',
        HttpStatus.UNAUTHORIZED,
      );
    }
    if (stored.expiresAt <= now) {
      throw new ApiException(
        ErrorCode.REFRESH_TOKEN_EXPIRED,
        'Refresh token has expired',
        HttpStatus.UNAUTHORIZED,
      );
    }

    const tokens = await this.signTokens(user.id, user.email);
    const newHash = this.hashToken(tokens.refreshToken);
    const expiresAt = this.getTokenExpiration(tokens.refreshToken);
    const rotated = await this.authRepository.rotateRefreshToken({
      currentTokenId: stored.id,
      userId: user.id,
      now,
      newTokenHash: newHash,
      expiresAt,
    });
    if (!rotated) {
      throw new ApiException(
        ErrorCode.REFRESH_TOKEN_REVOKED,
        'Refresh token has been revoked',
        HttpStatus.UNAUTHORIZED,
      );
    }

    return { message: 'Token refreshed successfully', data: tokens };
  }

  async logout(
    user: AuthUser,
    dto: RefreshTokenDto,
  ): Promise<ServiceResponse<null>> {
    let payload: { sub: number };
    try {
      payload = await this.jwt.verifyAsync<{ sub: number }>(dto.refreshToken, {
        secret: this.config.getOrThrow<string>('JWT_REFRESH_SECRET'),
      });
    } catch {
      throw new ApiException(
        ErrorCode.REFRESH_TOKEN_INVALID,
        'Refresh token is invalid',
        HttpStatus.UNAUTHORIZED,
      );
    }
    if (payload.sub !== user.id) {
      throw new ApiException(
        ErrorCode.REFRESH_TOKEN_INVALID,
        'Refresh token is invalid',
        HttpStatus.UNAUTHORIZED,
      );
    }

    const revoked = await this.authRepository.revokeRefreshToken(
      user.id,
      this.hashToken(dto.refreshToken),
      new Date(),
    );
    if (!revoked) {
      throw new ApiException(
        ErrorCode.REFRESH_TOKEN_REVOKED,
        'Refresh token is invalid or has been revoked',
        HttpStatus.UNAUTHORIZED,
      );
    }
    return { message: 'Logout successful', data: null };
  }

  private async issueAndStoreTokens(
    userId: number,
    email: string,
  ): Promise<TokenPair> {
    const tokens = await this.signTokens(userId, email);
    await this.authRepository.createRefreshToken(
      userId,
      this.hashToken(tokens.refreshToken),
      this.getTokenExpiration(tokens.refreshToken),
    );
    return tokens;
  }

  private async signTokens(userId: number, email: string): Promise<TokenPair> {
    const accessExpiresIn = this.config.get<string>(
      'JWT_ACCESS_EXPIRES_IN',
      '1d',
    ) as SignOptions['expiresIn'];
    const refreshExpiresIn = this.config.get<string>(
      'JWT_REFRESH_EXPIRES_IN',
      '7d',
    ) as SignOptions['expiresIn'];
    const [accessToken, refreshToken] = await Promise.all([
      this.jwt.signAsync(
        { sub: userId, email },
        {
          secret: this.config.getOrThrow<string>('JWT_ACCESS_SECRET'),
          expiresIn: accessExpiresIn,
        },
      ),
      this.jwt.signAsync(
        { sub: userId, email, jti: randomUUID() },
        {
          secret: this.config.getOrThrow<string>('JWT_REFRESH_SECRET'),
          expiresIn: refreshExpiresIn,
        },
      ),
    ]);
    return { accessToken, refreshToken };
  }

  private hashToken(token: string): string {
    return createHash('sha256').update(token).digest('hex');
  }

  private getTokenExpiration(token: string): Date {
    const decoded = this.jwt.decode<JwtExpirationPayload>(token);
    if (!decoded?.exp) {
      throw new Error('Generated refresh token has no expiration');
    }
    return new Date(decoded.exp * 1000);
  }
}
