import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../database/prisma.service';
import type { PublicAuthUser } from '../entities/auth.entity';

interface RotateRefreshTokenInput {
  currentTokenId: number;
  userId: number;
  now: Date;
  newTokenHash: string;
  expiresAt: Date;
}

@Injectable()
export class AuthRepository {
  constructor(private readonly prisma: PrismaService) {}

  findUserByEmail(email: string) {
    return this.prisma.user.findUnique({ where: { email } });
  }

  async createUser(
    email: string,
    passwordHash: string,
  ): Promise<PublicAuthUser | null> {
    try {
      return await this.prisma.user.create({
        data: { email, passwordHash },
        select: { id: true, email: true, createdAt: true },
      });
    } catch (error: unknown) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        return null;
      }
      throw error;
    }
  }

  findRefreshToken(tokenHash: string) {
    return this.prisma.refreshToken.findUnique({ where: { tokenHash } });
  }

  async createRefreshToken(
    userId: number,
    tokenHash: string,
    expiresAt: Date,
  ): Promise<void> {
    await this.prisma.refreshToken.create({
      data: { userId, tokenHash, expiresAt },
    });
  }

  async rotateRefreshToken(input: RotateRefreshTokenInput): Promise<boolean> {
    return this.prisma.$transaction(async (transaction) => {
      const revoked = await transaction.refreshToken.updateMany({
        where: {
          id: input.currentTokenId,
          userId: input.userId,
          revokedAt: null,
          expiresAt: { gt: input.now },
        },
        data: { revokedAt: input.now },
      });
      if (revoked.count !== 1) return false;

      await transaction.refreshToken.create({
        data: {
          userId: input.userId,
          tokenHash: input.newTokenHash,
          expiresAt: input.expiresAt,
        },
      });
      return true;
    });
  }

  async revokeRefreshToken(
    userId: number,
    tokenHash: string,
    revokedAt: Date,
  ): Promise<boolean> {
    const result = await this.prisma.refreshToken.updateMany({
      where: { userId, tokenHash, revokedAt: null },
      data: { revokedAt },
    });
    return result.count === 1;
  }
}
