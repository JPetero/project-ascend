import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class MuscleGroupsService {
  constructor(private readonly prisma: PrismaService) {}

  list() {
    return this.prisma.muscleGroup.findMany({ orderBy: { name: 'asc' } });
  }
}
