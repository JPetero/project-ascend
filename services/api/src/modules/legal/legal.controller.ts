import { Body, Controller, Get, Param, ParseEnumPipe, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { LegalDocumentType } from '@prisma/client';
import { Public } from '../../common/decorators/public.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/types/jwt-payload.type';
import { AcceptLegalDocumentDto } from './dto/accept-legal-document.dto';
import { LegalService } from './legal.service';

@ApiTags('legal')
@Controller('legal')
export class LegalController {
  constructor(private readonly legalService: LegalService) {}

  // Public: a user must be able to read the terms before registering.
  @Public()
  @Get('documents/:type/latest')
  getLatest(@Param('type', new ParseEnumPipe(LegalDocumentType)) type: LegalDocumentType) {
    return this.legalService.getLatest(type);
  }

  @ApiBearerAuth()
  @Get('acceptances/status')
  getAcceptanceStatus(@CurrentUser() user: AuthenticatedUser) {
    return this.legalService.getAcceptanceStatus(user.id);
  }

  @ApiBearerAuth()
  @Get('acceptances/me')
  listMine(@CurrentUser() user: AuthenticatedUser) {
    return this.legalService.listMine(user.id);
  }

  @ApiBearerAuth()
  @Post('acceptances')
  accept(@CurrentUser() user: AuthenticatedUser, @Body() dto: AcceptLegalDocumentDto) {
    return this.legalService.recordAcceptance(user.id, dto.legalDocumentId, dto.regionCode);
  }
}
