import { Body, Controller, Get, Put } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/types/jwt-payload.type';
import { UpsertMacroTargetDto } from './dto/upsert-macro-target.dto';
import { MacroTargetsService } from './macro-targets.service';

@ApiBearerAuth()
@ApiTags('macro-targets')
@Controller('macro-targets')
export class MacroTargetsController {
  constructor(private readonly macroTargetsService: MacroTargetsService) {}

  @Get()
  get(@CurrentUser() user: AuthenticatedUser) {
    return this.macroTargetsService.get(user.id);
  }

  @Put()
  upsert(@CurrentUser() user: AuthenticatedUser, @Body() dto: UpsertMacroTargetDto) {
    return this.macroTargetsService.upsert(user.id, dto);
  }
}
