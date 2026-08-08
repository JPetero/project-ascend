import { Body, Controller, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/types/jwt-payload.type';
import { VerifyPurchaseDto } from './dto/verify-purchase.dto';
import { PurchasesService } from './purchases.service';

@ApiBearerAuth()
@ApiTags('purchases')
@Controller('purchases')
export class PurchasesController {
  constructor(private readonly purchasesService: PurchasesService) {}

  @Post('verify')
  verify(@CurrentUser() user: AuthenticatedUser, @Body() dto: VerifyPurchaseDto) {
    return this.purchasesService.verifyAndRecord(user.id, dto);
  }
}
