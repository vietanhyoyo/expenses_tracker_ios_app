import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsIn,
  IsNumber,
  IsOptional,
  IsString,
  Matches,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

export class CreateAccountDto {
  @ApiProperty({ example: 'Ví điện tử', maxLength: 100 })
  @IsString()
  @Matches(/\S/, { message: 'name must not be empty' })
  @MaxLength(100)
  name!: string;

  @ApiProperty({ enum: ['cash', 'ewallet', 'bank'], example: 'ewallet' })
  @IsIn(['cash', 'ewallet', 'bank'])
  type!: 'cash' | 'ewallet' | 'bank';

  @ApiPropertyOptional({ example: 0, minimum: 0 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  @Max(9999999999999.99)
  initialBalance?: number;
}
