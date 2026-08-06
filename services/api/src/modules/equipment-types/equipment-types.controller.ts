import { Controller, Get } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { EquipmentTypesService } from './equipment-types.service';

@ApiBearerAuth()
@ApiTags('equipment-types')
@Controller('equipment-types')
export class EquipmentTypesController {
  constructor(private readonly equipmentTypesService: EquipmentTypesService) {}

  @Get()
  list() {
    return this.equipmentTypesService.list();
  }
}
