import { Body, Controller, Delete, Get, HttpCode, HttpStatus, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/types/jwt-payload.type';
import { AssistantReplyDto } from './dto/assistant-reply.dto';
import { AssistantService } from './assistant.service';

@ApiBearerAuth()
@ApiTags('assistant')
@Controller('assistant')
export class AssistantController {
  constructor(private readonly assistantService: AssistantService) {}

  @Post('reply')
  async reply(@CurrentUser() user: AuthenticatedUser, @Body() dto: AssistantReplyDto) {
    const reply = await this.assistantService.reply(dto, user.id);
    return { reply };
  }

  // Build Session 10 Part 15 — a real, inspectable surface for the
  // "AI memory" toggle that already existed: what got remembered, and a
  // way to clear it, rather than invisible state the user can't see.
  @Get('memory')
  async getMemory(@CurrentUser() user: AuthenticatedUser) {
    const notes = await this.assistantService.getMemory(user.id);
    return { notes };
  }

  @Delete('memory')
  @HttpCode(HttpStatus.NO_CONTENT)
  clearMemory(@CurrentUser() user: AuthenticatedUser) {
    return this.assistantService.clearMemory(user.id);
  }
}
