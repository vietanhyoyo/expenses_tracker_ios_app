import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, Matches } from 'class-validator';

export class QueryDashboardSummaryDto {
  @ApiPropertyOptional({
    example: '2026-09',
    pattern: '^\\d{4}-(0[1-9]|1[0-2])$',
  })
  @IsOptional()
  @Matches(/^\d{4}-(0[1-9]|1[0-2])$/, {
    message: 'month must use YYYY-MM format',
  })
  month = new Date().toISOString().slice(0, 7);
}
