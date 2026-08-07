import { ApiProperty } from '@nestjs/swagger';
import { IsString, MinLength } from 'class-validator';

/**
 * Local-dev-only completion body. Real production uploads go straight
 * to cloud storage over a presigned PUT and never touch our API with
 * the file bytes — this base64 JSON body is a same-origin stand-in that
 * needs no raw-body middleware config, used only by
 * `LocalDevelopmentStorageProvider`'s upload target.
 */
export class LocalBytesDto {
  @ApiProperty()
  @IsString()
  @MinLength(1)
  base64!: string;
}
