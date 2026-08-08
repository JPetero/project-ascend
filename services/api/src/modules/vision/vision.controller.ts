import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Post,
  Query,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { PaginationQueryDto } from '../../common/pagination/pagination-query.dto';
import { AuthenticatedUser } from '../auth/types/jwt-payload.type';
import { CreateVisionAnalysisSessionDto } from './dto/create-vision-analysis-session.dto';
import { VisionService } from './vision.service';

@ApiBearerAuth()
@ApiTags('vision')
@Controller('vision/analysis-sessions')
export class VisionController {
  constructor(private readonly visionService: VisionService) {}

  @Post()
  create(@CurrentUser() user: AuthenticatedUser, @Body() dto: CreateVisionAnalysisSessionDto) {
    return this.visionService.createSession(user.id, dto);
  }

  @Get()
  list(@CurrentUser() user: AuthenticatedUser, @Query() query: PaginationQueryDto) {
    return this.visionService.listSessions(user.id, query);
  }

  @Get(':id')
  get(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.visionService.getSession(user.id, id);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  remove(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.visionService.deleteSession(user.id, id);
  }
}
