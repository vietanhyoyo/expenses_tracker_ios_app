import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsDateString, IsIn, IsOptional } from 'class-validator';

export class QueryDashboardSummaryDto {
  @ApiPropertyOptional({ enum: ['week', 'month', 'year'], default: 'month' })
  @IsIn(['week', 'month', 'year'])
  @IsOptional()
  period: 'week' | 'month' | 'year' = 'month';

  @ApiPropertyOptional({ example: '2026-09-23' })
  @IsDateString({ strict: true })
  @IsOptional()
  date = new Date().toISOString().slice(0, 10);
}
