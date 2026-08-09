import { Body, Controller, Delete, Get, HttpCode, HttpStatus, Param, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/types/jwt-payload.type';
import { AssistantReplyDto } from './dto/assistant-reply.dto';
import { ConfirmMemoryDto } from './dto/confirm-memory.dto';
import { AssistantService } from './assistant.service';

@ApiBearerAuth()
@ApiTags('assistant')
@Controller('assistant')
export class AssistantController {
  constructor(private readonly assistantService: AssistantService) {}

  @Post('reply')
  async reply(@CurrentUser() user: AuthenticatedUser, @Body() dto: AssistantReplyDto) {
    return this.assistantService.reply(dto, user.id);
  }

  // Build Session 12 Part 4 — confirms a SENSITIVE memory candidate
  // `reply` surfaced but did not auto-save.
  @Post('memory/confirm')
  @HttpCode(HttpStatus.NO_CONTENT)
  confirmMemory(@CurrentUser() user: AuthenticatedUser, @Body() dto: ConfirmMemoryDto) {
    return this.assistantService.confirmMemory(user.id, dto);
  }

  // Build Session 10 Part 15 — a real, inspectable surface for the "AI
  // memory" toggle that already existed. Build Session 11 Part 4:
  // `notes` is now a list of structured, categorized facts (id,
  // category, value, createdAt) instead of raw remembered sentences.
  @Get('memory')
  async getMemory(@CurrentUser() user: AuthenticatedUser) {
    const notes = await this.assistantService.getMemory(user.id);
    return { notes };
  }

  // Build Session 11 Part 4 — delete one remembered fact without
  // clearing everything, the concrete gap the directive called out
  // ("list memories... delete one").
  @Delete('memory/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  deleteMemoryNote(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.assistantService.deleteMemory(user.id, id);
  }

  @Delete('memory')
  @HttpCode(HttpStatus.NO_CONTENT)
  clearMemory(@CurrentUser() user: AuthenticatedUser) {
    return this.assistantService.clearMemory(user.id);
  }
}
