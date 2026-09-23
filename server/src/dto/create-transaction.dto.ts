import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsDateString,
  IsIn,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  Matches,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

export class CreateTransactionDto {
  @ApiProperty({ enum: ['income', 'expense'] })
  @IsIn(['income', 'expense'])
  type!: 'income' | 'expense';

  @ApiProperty({ example: 'Salary', maxLength: 150 })
  @IsString()
  @Matches(/\S/, { message: 'title must not be empty' })
  @MaxLength(150)
  title!: string;

  @ApiProperty({ example: 120000, minimum: 0.01 })
  @Type(() => Number)
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0.01)
  @Max(9999999999999.99)
  amount!: number;

  @ApiProperty({ example: '2026-09-23' })
  @IsDateString({ strict: true })
  transactionDate!: string;

  @ApiProperty({ example: 1 })
  @Type(() => Number)
  @IsInt()
  @Min(1)
  categoryId!: number;

  @ApiPropertyOptional({ example: 'Monthly salary', maxLength: 2000 })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  notes?: string;
}
