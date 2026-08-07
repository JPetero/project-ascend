import { Controller, Get } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/types/jwt-payload.type';
import { DataExportService } from './data-export.service';

@ApiBearerAuth()
@ApiTags('data-export')
@Controller('account/data-export')
export class DataExportController {
  constructor(private readonly dataExportService: DataExportService) {}

  @Get()
  exportMyData(@CurrentUser() user: AuthenticatedUser) {
    return this.dataExportService.exportMyData(user.id);
  }
}
