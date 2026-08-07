import { ApiProperty } from '@nestjs/swagger';
import { SupportTicketCategory } from '@prisma/client';
import { IsEnum, IsString, MaxLength, MinLength } from 'class-validator';

export class CreateTicketDto {
  @ApiProperty({ enum: SupportTicketCategory })
  @IsEnum(SupportTicketCategory)
  category!: SupportTicketCategory;

  @ApiProperty()
  @IsString()
  @MinLength(1)
  @MaxLength(150)
  subject!: string;

  @ApiProperty()
  @IsString()
  @MinLength(1)
  @MaxLength(5000)
  message!: string;
}
