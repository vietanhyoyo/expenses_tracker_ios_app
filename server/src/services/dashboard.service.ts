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
    const anchor = this.parseCalendarDate(query.date);
    const range = this.rangeFor(query.period, anchor);
    const values = await this.repository.summary(userId, range.from, range.to);
    return {
      message: 'Dashboard summary retrieved successfully',
      data: {
        month: query.date.slice(0, 7),
        period: query.period,
        from: this.formatCalendarDate(range.from),
        to: this.formatCalendarDate(range.to),
        totalBalance: values.totalIncome.minus(values.totalExpense),
        monthlyIncome: values.monthlyIncome,
        monthlyExpense: values.monthlyExpense,
        monthlyBalance: values.monthlyIncome.minus(values.monthlyExpense),
      },
    };
  }

  private parseCalendarDate(value: string): Date {
    const [year, month, day] = value.split('-').map(Number);
    return new Date(Date.UTC(year, month - 1, day));
  }

  private rangeFor(
    period: QueryDashboardSummaryDto['period'],
    anchor: Date,
  ): { from: Date; to: Date } {
    if (period === 'year') {
      const from = new Date(Date.UTC(anchor.getUTCFullYear(), 0, 1));
      return {
        from,
        to: new Date(Date.UTC(anchor.getUTCFullYear() + 1, 0, 1)),
      };
    }
    if (period === 'month') {
      const from = new Date(
        Date.UTC(anchor.getUTCFullYear(), anchor.getUTCMonth(), 1),
      );
      return {
        from,
        to: new Date(
          Date.UTC(anchor.getUTCFullYear(), anchor.getUTCMonth() + 1, 1),
        ),
      };
    }

    const dayOffset = (anchor.getUTCDay() + 6) % 7;
    const from = new Date(
      Date.UTC(
        anchor.getUTCFullYear(),
        anchor.getUTCMonth(),
        anchor.getUTCDate() - dayOffset,
      ),
    );
    return {
      from,
      to: new Date(
        Date.UTC(
          from.getUTCFullYear(),
          from.getUTCMonth(),
          from.getUTCDate() + 7,
        ),
      ),
    };
  }

  private formatCalendarDate(date: Date): string {
    return date.toISOString().slice(0, 10);
  }
}
