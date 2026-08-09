import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class ResearchQueryDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(500)
  query!: string;
}
