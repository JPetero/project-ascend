import { Body, Controller, Get, Param, Patch, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AdminGuard } from '../../common/guards/admin.guard';
import { AuthenticatedUser } from '../auth/types/jwt-payload.type';
import { AdminService } from './admin.service';
import { ActionReportDto } from './dto/action-report.dto';
import { DecideEligibilityDto } from './dto/decide-eligibility.dto';
import { ListEligibilityDto } from './dto/list-eligibility.dto';
import { ListReportsDto } from './dto/list-reports.dto';
import { ListTicketsDto } from './dto/list-tickets.dto';
import { AdminReplyTicketDto } from './dto/reply-ticket.dto';

@ApiBearerAuth()
@ApiTags('admin')
@UseGuards(AdminGuard)
@Controller('admin')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('community-reports')
  listReports(@Query() query: ListReportsDto) {
    return this.adminService.listReports(query);
  }

  @Patch('community-reports/:id')
  actionReport(@Param('id') id: string, @Body() dto: ActionReportDto) {
    return this.adminService.actionReport(id, dto);
  }

  @Get('eligibility-applications')
  listEligibilityApplications(@Query() query: ListEligibilityDto) {
    return this.adminService.listEligibilityApplications(query);
  }

  @Patch('eligibility-applications/:userId')
  decideEligibility(@Param('userId') userId: string, @Body() dto: DecideEligibilityDto) {
    return this.adminService.decideEligibility(userId, dto);
  }

  @Get('support-tickets')
  listTickets(@Query() query: ListTicketsDto) {
    return this.adminService.listTickets(query);
  }

  @Get('support-tickets/:id')
  getTicket(@Param('id') id: string) {
    return this.adminService.getTicket(id);
  }

  @Patch('support-tickets/:id/reply')
  replyToTicket(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: AdminReplyTicketDto,
  ) {
    return this.adminService.replyToTicket(user.id, id, dto);
  }
}
