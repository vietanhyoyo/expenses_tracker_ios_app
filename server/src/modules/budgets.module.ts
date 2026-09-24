import { Module } from '@nestjs/common';
import { BudgetsController } from '../controllers/budgets.controller';
import { BudgetsRepository } from '../repositories/budgets.repository';
import { BudgetsService } from '../services/budgets.service';

@Module({
  controllers: [BudgetsController],
  providers: [BudgetsService, BudgetsRepository],
})
export class BudgetsModule {}
