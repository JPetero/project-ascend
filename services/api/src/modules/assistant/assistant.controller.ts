import { Body, Controller, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AssistantReplyDto } from './dto/assistant-reply.dto';
import { AssistantService } from './assistant.service';

@ApiBearerAuth()
@ApiTags('assistant')
@Controller('assistant')
export class AssistantController {
  constructor(private readonly assistantService: AssistantService) {}

  @Post('reply')
  async reply(@Body() dto: AssistantReplyDto) {
    const reply = await this.assistantService.reply(dto);
    return { reply };
  }
}
