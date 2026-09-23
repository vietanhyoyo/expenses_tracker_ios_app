import { Injectable } from '@nestjs/common';
import type { ServiceResponse } from '../common/interfaces/api-response.interface';
import type { QueryDashboardSummaryDto } from '../dto/query-dashboard-summary.dto';
import type { DashboardSummaryEntity } from '../entities/dashboard.entity';
import { DashboardRepository } from '../repositories/dashboard.repository';

@Injectable()
export class DashboardService {
  constructor(private readonly repository: DashboardRepository) {}

  async summary(
    userId: number,
    query: QueryDashboardSummaryDto,
  ): Promise<ServiceResponse<DashboardSummaryEntity>> {
    const [year, month] = query.month.split('-').map(Number);
    const from = new Date(Date.UTC(year, month - 1, 1));
    const to = new Date(Date.UTC(year, month, 1));
    const values = await this.repository.summary(userId, from, to);
    return {
      message: 'Dashboard summary retrieved successfully',
      data: {
        month: query.month,
        totalBalance: values.totalIncome.minus(values.totalExpense),
        monthlyIncome: values.monthlyIncome,
        monthlyExpense: values.monthlyExpense,
        monthlyBalance: values.monthlyIncome.minus(values.monthlyExpense),
      },
    };
  }
}
