import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import type { Request } from 'express';
import { ExtractJwt, Strategy } from 'passport-jwt';
import type { RefreshAuthUser } from '../common/interfaces/auth-user.interface';

interface RefreshJwtPayload {
  sub: number;
  email: string;
  exp: number;
}

interface RefreshRequestBody {
  refreshToken?: unknown;
}

@Injectable()
export class RefreshTokenStrategy extends PassportStrategy(
  Strategy,
  'jwt-refresh',
) {
  constructor(config: ConfigService) {
    super({
      jwtFromRequest: ExtractJwt.fromBodyField('refreshToken'),
      ignoreExpiration: false,
      secretOrKey: config.getOrThrow<string>('JWT_REFRESH_SECRET'),
      passReqToCallback: true,
    });
  }

  validate(request: Request, payload: RefreshJwtPayload): RefreshAuthUser {
    const body = request.body as RefreshRequestBody;
    return {
      id: payload.sub,
      email: payload.email,
      exp: payload.exp,
      refreshToken:
        typeof body.refreshToken === 'string' ? body.refreshToken : '',
    };
  }
}
