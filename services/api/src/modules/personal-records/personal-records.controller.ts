import { Controller, Get } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/types/jwt-payload.type';
import { PersonalRecordsService } from './personal-records.service';

@ApiBearerAuth()
@ApiTags('personal-records')
@Controller('personal-records')
export class PersonalRecordsController {
  constructor(private readonly personalRecordsService: PersonalRecordsService) {}

  @Get()
  list(@CurrentUser() user: AuthenticatedUser) {
    return this.personalRecordsService.list(user.id);
  }
}
