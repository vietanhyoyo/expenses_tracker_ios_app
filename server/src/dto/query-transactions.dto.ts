import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsDateString,
  IsIn,
  IsInt,
  IsOptional,
  Max,
  Min,
} from 'class-validator';

export class QueryTransactionsDto {
  @ApiPropertyOptional({ default: 1, minimum: 1 })
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @IsOptional()
  page = 1;

  @ApiPropertyOptional({ default: 20, minimum: 1, maximum: 100 })
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  @IsOptional()
  limit = 20;

  @ApiPropertyOptional({ enum: ['income', 'expense'] })
  @IsIn(['income', 'expense'])
  @IsOptional()
  type?: 'income' | 'expense';

  @ApiPropertyOptional({ type: Number })
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @IsOptional()
  categoryId?: number;

  @ApiPropertyOptional({ example: '2026-09-01' })
  @IsDateString({ strict: true })
  @IsOptional()
  from?: string;

  @ApiPropertyOptional({ example: '2026-09-30' })
  @IsDateString({ strict: true })
  @IsOptional()
  to?: string;

  @ApiPropertyOptional({
    enum: ['transactionDate', 'amount', 'createdAt'],
    default: 'transactionDate',
  })
  @IsIn(['transactionDate', 'amount', 'createdAt'])
  @IsOptional()
  sortBy: 'transactionDate' | 'amount' | 'createdAt' = 'transactionDate';

  @ApiPropertyOptional({ enum: ['asc', 'desc'], default: 'desc' })
  @IsIn(['asc', 'desc'])
  @IsOptional()
  sortOrder: 'asc' | 'desc' = 'desc';
}
