import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsInt, Min } from 'class-validator';

export class DeleteCategoryDto {
  @ApiProperty({
    example: 1,
    description: 'Category that receives expenses from the deleted category',
  })
  @Type(() => Number)
  @IsInt()
  @Min(1)
  replacementCategoryId!: number;
}
