import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  StreamableFile,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/types/jwt-payload.type';
import { InitiateUploadDto } from './dto/initiate-upload.dto';
import { LocalBytesDto } from './dto/local-bytes.dto';
import { ReportMediaDto } from './dto/report-media.dto';
import { SetVisibilityDto } from './dto/set-visibility.dto';
import { MediaService } from './media.service';

@ApiBearerAuth()
@ApiTags('media')
@Controller('media')
export class MediaController {
  constructor(private readonly mediaService: MediaService) {}

  @Post('uploads')
  initiateUpload(@CurrentUser() user: AuthenticatedUser, @Body() dto: InitiateUploadDto) {
    return this.mediaService.initiateUpload(user.id, dto);
  }

  // Build Session 12 Part 18-21 — local-dev-only object serving route,
  // authenticated + visibility-checked (see MediaService.readLocalObject
  // and LocalDevelopmentStorageProvider.getSignedGetUrl's doc comment).
  // `key` is a query param, not a path segment, so a storage key
  // containing "/" never has to survive Express's path-segment decoding.
  @Get('objects')
  async getObject(
    @CurrentUser() user: AuthenticatedUser,
    @Query('key') key: string,
  ): Promise<StreamableFile> {
    const { buffer, mimeType } = await this.mediaService.readLocalObject(user.id, key);
    return new StreamableFile(buffer, { type: mimeType });
  }

  // Local-dev-only completion path — see LocalDevelopmentStorageProvider.
  @Post('uploads/:id/local-bytes')
  async receiveLocalBytes(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: LocalBytesDto,
  ) {
    await this.mediaService.receiveLocalBytes(user.id, id, Buffer.from(dto.base64, 'base64'));
    return { received: true };
  }

  @Get('mine')
  listMine(@CurrentUser() user: AuthenticatedUser) {
    return this.mediaService.listMine(user.id);
  }

  @Get(':id')
  getById(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.mediaService.getById(user.id, id);
  }

  @Post(':id/complete')
  complete(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.mediaService.completeUpload(user.id, id);
  }

  @Patch(':id/visibility')
  setVisibility(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: SetVisibilityDto,
  ) {
    return this.mediaService.setVisibility(user.id, id, dto.visibility);
  }

  @Delete(':id')
  async remove(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    await this.mediaService.deleteAsset(user.id, id);
    return { deleted: true };
  }

  @Post(':id/report')
  report(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: ReportMediaDto,
  ) {
    return this.mediaService.reportAsset(user.id, id, dto.reason);
  }
}
