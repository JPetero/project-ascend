import { ApiProperty } from '@nestjs/swagger';
import { IsString, MinLength } from 'class-validator';

export class SearchUsersDto {
  @ApiProperty()
  @IsString()
  @MinLength(2)
  query!: string;
}
