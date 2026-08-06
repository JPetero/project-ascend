import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class ExerciseCategoriesService {
  constructor(private readonly prisma: PrismaService) {}

  list() {
    return this.prisma.exerciseCategory.findMany({ orderBy: { name: 'asc' } });
  }
}
