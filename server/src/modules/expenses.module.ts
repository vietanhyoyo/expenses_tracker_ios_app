import { Module } from '@nestjs/common';
import { ExpensesController } from '../controllers/expenses.controller';
import { ExpensesRepository } from '../repositories/expenses.repository';
import { ExpensesService } from '../services/expenses.service';

@Module({
  controllers: [ExpensesController],
  providers: [ExpensesService, ExpensesRepository],
})
export class ExpensesModule {}
