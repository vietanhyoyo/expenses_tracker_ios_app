import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Patch,
  Post,
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
import { CreateAccountDto } from '../dto/create-account.dto';
import { UpdateAccountDto } from '../dto/update-account.dto';
import { AccountsService } from '../services/accounts.service';

@ApiTags('Accounts')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('accounts')
export class AccountsController {
  constructor(private readonly accountsService: AccountsService) {}

  @Get()
  @ApiOperation({
    summary: 'List current-user accounts and default account types',
  })
  findAll(@CurrentUser() user: AuthUser) {
    return this.accountsService.findAll(user.id);
  }

  @Post()
  @ApiOperation({ summary: 'Create a custom account' })
  create(@CurrentUser() user: AuthUser, @Body() dto: CreateAccountDto) {
    return this.accountsService.create(user.id, dto);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update an owned account' })
  @ApiParam({ name: 'id', type: Number })
  update(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpdateAccountDto,
  ) {
    return this.accountsService.update(user.id, id, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete an owned custom account' })
  @ApiParam({ name: 'id', type: Number })
  remove(@CurrentUser() user: AuthUser, @Param('id', ParseIntPipe) id: number) {
    return this.accountsService.remove(user.id, id);
  }
}
