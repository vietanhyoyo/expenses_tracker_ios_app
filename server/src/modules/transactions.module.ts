import { Module } from '@nestjs/common';
import { TransactionsController } from '../controllers/transactions.controller';
import { ExpensesRepository } from '../repositories/expenses.repository';
import { TransactionsService } from '../services/transactions.service';

@Module({
  controllers: [TransactionsController],
  providers: [TransactionsService, ExpensesRepository],
})
export class TransactionsModule {}
