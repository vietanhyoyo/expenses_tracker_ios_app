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

  @ApiProperty({
    example: '#7C3AED',
    required: false,
    description: 'Category color in #RRGGBB format',
  })
  @IsOptional()
  @IsString()
  @Matches(/^#[0-9A-Fa-f]{6}$/, {
    message: 'colorHex must use the #RRGGBB format',
  })
  colorHex?: string;

  @ApiProperty({ enum: ['income', 'expense'], default: 'expense' })
  @IsOptional()
  @IsIn(['income', 'expense'])
  type?: 'income' | 'expense';
}
