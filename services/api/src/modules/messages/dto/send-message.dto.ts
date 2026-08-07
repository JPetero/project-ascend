import { ApiPropertyOptional } from '@nestjs/swagger';
import { DirectMessageType } from '@prisma/client';
import {
  ArrayMaxSize,
  IsArray,
  IsEnum,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  ValidateIf,
} from 'class-validator';

export class SendMessageDto {
  @ApiPropertyOptional({ enum: DirectMessageType, default: DirectMessageType.TEXT })
  @IsOptional()
  @IsEnum(DirectMessageType)
  type?: DirectMessageType;

  @ApiPropertyOptional()
  @ValidateIf((o: SendMessageDto) => (o.type ?? DirectMessageType.TEXT) === DirectMessageType.TEXT)
  @IsString()
  @MaxLength(4000)
  body?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  replyToId?: string;

  // Required for a *_SHARE type — see schema.prisma's DirectMessage doc
  // comment on what this references.
  @ApiPropertyOptional()
  @ValidateIf((o: SendMessageDto) => (o.type ?? DirectMessageType.TEXT) !== DirectMessageType.TEXT)
  @IsUUID()
  sharedReferenceId?: string;

  @ApiPropertyOptional({ type: [String] })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(4)
  @IsUUID('4', { each: true })
  mediaAssetIds?: string[];
}
