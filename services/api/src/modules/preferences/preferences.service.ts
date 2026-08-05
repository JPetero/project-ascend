import { Injectable, NotFoundException } from '@nestjs/common';
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
    await this.getPreferences(userId);
    return this.prisma.preference.update({ where: { userId }, data: dto });
  }
}
