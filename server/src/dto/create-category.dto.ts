import { ApiProperty } from '@nestjs/swagger';
import {
  IsIn,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
} from 'class-validator';

export class CreateCategoryDto {
  @ApiProperty({ example: 'Gym', maxLength: 100 })
  @IsString()
  @Matches(/\S/, { message: 'name must not be empty' })
  @MaxLength(100)
  name!: string;

  @ApiProperty({ enum: ['income', 'expense'], default: 'expense' })
  @IsOptional()
  @IsIn(['income', 'expense'])
  type?: 'income' | 'expense';
}
