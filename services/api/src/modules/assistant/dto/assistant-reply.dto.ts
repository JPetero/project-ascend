import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  ValidateNested,
} from 'class-validator';
import { CoachingStyleDto, CompanionDto } from '../assistant.types';

export { CoachingStyleDto, CompanionDto };

/**
 * One prior chat turn, mirroring `ChatMessage` on the mobile side — only
 * what the model needs to follow the conversation, nothing persisted
 * server-side (see AssistantService's doc comment).
 */
export class AssistantHistoryMessageDto {
  @IsString()
  @MaxLength(4000)
  text!: string;

  @IsBoolean()
  isFromUser!: boolean;
}

export class AssistantReplyDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(4000)
  input!: string;

  @IsEnum(CompanionDto)
  companion!: CompanionDto;

  @IsEnum(CoachingStyleDto)
  style!: CoachingStyleDto;

  // Capped well below what a real conversation would ever need — this is
  // context for the model, not a transcript store.
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(20)
  @ValidateNested({ each: true })
  @Type(() => AssistantHistoryMessageDto)
  history?: AssistantHistoryMessageDto[];

  // Build Session 12 Part 8 — omitted on the first turn of a new
  // conversation; the server creates one and returns its id. Sent back
  // on every subsequent turn so replies append to the same conversation
  // instead of each turn silently starting a new one. Never trusted
  // blindly: CompanionConversationsService.appendTurn re-checks
  // ownership (`userId` match) before appending, and falls back to
  // creating a fresh conversation rather than erroring if this doesn't
  // resolve to one this user owns.
  @IsOptional()
  @IsUUID()
  conversationId?: string;
}
