import { Body, Controller, Delete, Get, Param, Patch, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/types/jwt-payload.type';
import { AddGalleryMediaDto } from './dto/add-gallery-media.dto';
import { CreateGalleryAlbumDto } from './dto/create-gallery-album.dto';
import { UpdateGalleryAlbumDto } from './dto/update-gallery-album.dto';
import { GalleryService } from './gallery.service';

@ApiBearerAuth()
@ApiTags('gallery')
@Controller('gallery')
export class GalleryController {
  constructor(private readonly galleryService: GalleryService) {}

  @Get('albums')
  listAlbums(@CurrentUser() user: AuthenticatedUser) {
    return this.galleryService.listAlbums(user.id);
  }

  @Post('albums')
  createAlbum(@CurrentUser() user: AuthenticatedUser, @Body() dto: CreateGalleryAlbumDto) {
    return this.galleryService.createAlbum(user.id, dto);
  }

  @Get('albums/:id')
  getAlbum(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.galleryService.getAlbum(user.id, id);
  }

  @Patch('albums/:id')
  updateAlbum(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: UpdateGalleryAlbumDto,
  ) {
    return this.galleryService.updateAlbum(user.id, id, dto);
  }

  @Delete('albums/:id')
  async deleteAlbum(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    await this.galleryService.deleteAlbum(user.id, id);
    return { deleted: true };
  }

  @Post('albums/:id/media')
  addMedia(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') albumId: string,
    @Body() dto: AddGalleryMediaDto,
  ) {
    return this.galleryService.addMedia(user.id, albumId, dto);
  }

  @Delete('media/:id')
  async removeMedia(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    await this.galleryService.removeMedia(user.id, id);
    return { deleted: true };
  }

  @Post('media/:id/set-avatar')
  async setAsAvatar(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    await this.galleryService.setAsAvatar(user.id, id);
    return { updated: true };
  }

  @Post('media/:id/set-cover')
  async setAsCover(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    await this.galleryService.setAsCover(user.id, id);
    return { updated: true };
  }
}
