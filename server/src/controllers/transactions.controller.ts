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
import { CreateTransactionDto } from '../dto/create-transaction.dto';
import { QueryTransactionTrendDto } from '../dto/query-transaction-trend.dto';
import { QueryTransactionsDto } from '../dto/query-transactions.dto';
import { UpdateTransactionDto } from '../dto/update-transaction.dto';
import { TransactionsService } from '../services/transactions.service';

@ApiTags('Transactions')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('transactions')
export class TransactionsController {
  constructor(private readonly service: TransactionsService) {}

  @Post()
  @ApiOperation({ summary: 'Create an income or expense transaction' })
  create(@CurrentUser() user: AuthUser, @Body() dto: CreateTransactionDto) {
    return this.service.create(user.id, dto);
  }

  @Get()
  @ApiOperation({ summary: 'List, filter, paginate, and sort transactions' })
  findAll(@CurrentUser() user: AuthUser, @Query() query: QueryTransactionsDto) {
    return this.service.findAll(user.id, query);
  }

  @Get('trend')
  @ApiOperation({ summary: 'Get income or expense trend grouped by day or month' })
  trend(
    @CurrentUser() user: AuthUser,
    @Query() query: QueryTransactionTrendDto,
  ) {
    return this.service.trend(user.id, query);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get an owned transaction' })
  @ApiParam({ name: 'id', type: Number })
  findOne(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseIntPipe) id: number,
  ) {
    return this.service.findOne(user.id, id);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update an owned transaction' })
  @ApiParam({ name: 'id', type: Number })
  update(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpdateTransactionDto,
  ) {
    return this.service.update(user.id, id, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete an owned transaction' })
  @ApiParam({ name: 'id', type: Number })
  remove(@CurrentUser() user: AuthUser, @Param('id', ParseIntPipe) id: number) {
    return this.service.remove(user.id, id);
  }
}
