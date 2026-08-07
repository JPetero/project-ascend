import { ApiProperty } from '@nestjs/swagger';
import { MediaType } from '@prisma/client';
import { IsEnum, IsInt, IsOptional, IsPositive, IsString, MaxLength, Min } from 'class-validator';

export class InitiateUploadDto {
  @ApiProperty({ enum: MediaType })
  @IsEnum(MediaType)
  mediaType!: MediaType;

  @ApiProperty()
  @IsString()
  @MaxLength(255)
  originalFilename!: string;

  @ApiProperty()
  @IsString()
  mimeType!: string;

  @ApiProperty()
  @IsInt()
  @IsPositive()
  sizeBytes!: number;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsInt()
  @Min(1)
  width?: number;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsInt()
  @Min(1)
  height?: number;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsInt()
  @Min(0)
  durationSeconds?: number;
}
