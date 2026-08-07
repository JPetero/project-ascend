import { ApiProperty } from '@nestjs/swagger';
import { AuthProvider } from '@prisma/client';
import { IsIn, IsString } from 'class-validator';

export class LinkIdentityDto {
  @ApiProperty({ enum: ['GOOGLE', 'APPLE'] })
  @IsIn(['GOOGLE', 'APPLE'])
  provider!: Extract<AuthProvider, 'GOOGLE' | 'APPLE'>;

  @ApiProperty()
  @IsString()
  idToken!: string;
}
