import { ApiProperty } from '@nestjs/swagger';
import { IsString } from 'class-validator';

export class GoogleSignInDto {
  @ApiProperty()
  @IsString()
  idToken!: string;
}
