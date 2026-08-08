import { ApiProperty } from '@nestjs/swagger';
import { AdminPermission } from '@prisma/client';
import { IsEnum } from 'class-validator';

export class GrantAdminPermissionDto {
  @ApiProperty({ enum: AdminPermission })
  @IsEnum(AdminPermission)
  permission!: AdminPermission;
}
