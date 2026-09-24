import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerModule } from '@nestjs/throttler';
import { ThrottlerGuard } from '@nestjs/throttler';
import { validateEnvironment } from './config/env.validation';
import { AuthModule } from './modules/auth.module';
import { CategoriesModule } from './modules/categories.module';
import { ExpensesModule } from './modules/expenses.module';
import { DashboardModule } from './modules/dashboard.module';
import { PrismaModule } from './modules/prisma.module';
import { UsersModule } from './modules/users.module';
import { TransactionsModule } from './modules/transactions.module';
import { AccountsModule } from './modules/accounts.module';
import { BudgetsModule } from './modules/budgets.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, validate: validateEnvironment }),
    ThrottlerModule.forRoot([{ ttl: 60_000, limit: 100 }]),
    PrismaModule,
    AuthModule,
    UsersModule,
    CategoriesModule,
    ExpensesModule,
    TransactionsModule,
    DashboardModule,
    AccountsModule,
    BudgetsModule,
  ],
  providers: [{ provide: APP_GUARD, useClass: ThrottlerGuard }],
})
export class AppModule {}
