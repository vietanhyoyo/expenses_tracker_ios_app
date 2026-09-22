import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiParam,
  ApiTags,
} from '@nestjs/swagger';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { CreateExpenseDto } from '../dto/create-expense.dto';
import { QueryExpensesDto } from '../dto/query-expenses.dto';
import { UpdateExpenseDto } from '../dto/update-expense.dto';
import { ExpensesService } from '../services/expenses.service';

@ApiTags('Expenses')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('expenses')
export class ExpensesController {
  constructor(private readonly expensesService: ExpensesService) {}

  @Post()
  @ApiOperation({ summary: 'Create an expense' })
  create(@CurrentUser() user: AuthUser, @Body() dto: CreateExpenseDto) {
    return this.expensesService.create(user.id, dto);
  }

  @Get()
  @ApiOperation({ summary: 'List, filter, paginate, and sort owned expenses' })
  findAll(@CurrentUser() user: AuthUser, @Query() query: QueryExpensesDto) {
    return this.expensesService.findAll(user.id, query);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get an owned expense' })
  @ApiParam({ name: 'id', type: Number })
  findOne(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseIntPipe) id: number,
  ) {
    return this.expensesService.findOne(user.id, id);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update an owned expense' })
  @ApiParam({ name: 'id', type: Number })
  update(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpdateExpenseDto,
  ) {
    return this.expensesService.update(user.id, id, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete an owned expense' })
  @ApiParam({ name: 'id', type: Number })
  remove(@CurrentUser() user: AuthUser, @Param('id', ParseIntPipe) id: number) {
    return this.expensesService.remove(user.id, id);
  }
}
