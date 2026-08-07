import { ApiProperty } from '@nestjs/swagger';
import { IsString, MaxLength } from 'class-validator';

export class CreateCommunityCommentDto {
  @ApiProperty()
  @IsString()
  @MaxLength(1000)
  body!: string;
}
