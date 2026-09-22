import { Injectable } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';
import type { UserEntity } from '../entities/user.entity';

@Injectable()
export class UsersRepository {
  constructor(private readonly prisma: PrismaService) {}

  findPublicById(userId: number): Promise<UserEntity | null> {
    return this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, email: true, createdAt: true, updatedAt: true },
    });
  }
}
