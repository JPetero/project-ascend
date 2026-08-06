import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/types/jwt-payload.type';
import { LogWaterDto } from './dto/log-water.dto';
import { QueryWaterDto } from './dto/query-water.dto';
import { UpdateWaterDto } from './dto/update-water.dto';
import { WaterService } from './water.service';

@ApiBearerAuth()
@ApiTags('water')
@Controller('water')
export class WaterController {
  constructor(private readonly waterService: WaterService) {}

  @Get()
  getDaily(@CurrentUser() user: AuthenticatedUser, @Query() query: QueryWaterDto) {
    return this.waterService.getDaily(user.id, query.date);
  }

  @Post()
  addEntry(@CurrentUser() user: AuthenticatedUser, @Body() dto: LogWaterDto) {
    return this.waterService.addEntry(user.id, dto);
  }

  @Patch(':id')
  updateEntry(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: UpdateWaterDto,
  ) {
    return this.waterService.updateEntry(user.id, id, dto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  deleteEntry(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.waterService.deleteEntry(user.id, id);
  }
}
