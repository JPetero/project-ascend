import { Injectable, NotFoundException } from '@nestjs/common';
import { isPrismaNotFoundError } from '../../common/prisma/prisma-errors.util';
import { PrismaService } from '../../prisma/prisma.service';
import { UpdatePreferencesDto } from './dto/update-preferences.dto';

@Injectable()
export class PreferencesService {
  constructor(private readonly prisma: PrismaService) {}

  async getPreferences(userId: string) {
    const preference = await this.prisma.preference.findUnique({ where: { userId } });
    if (!preference) {
      throw new NotFoundException('Preferences not found.');
    }
    return preference;
  }

  async updatePreferences(userId: string, dto: UpdatePreferencesDto) {
    try {
      return await this.prisma.preference.update({ where: { userId }, data: dto });
    } catch (error) {
      if (isPrismaNotFoundError(error)) {
        throw new NotFoundException('Preferences not found.');
      }
      throw error;
    }
  }
}
