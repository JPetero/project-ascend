import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
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
}
