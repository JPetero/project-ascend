import { Injectable, NotFoundException } from '@nestjs/common';
import { LegalDocumentType } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';

/**
 * Scenario 1 (see packages/docs/product/user-scenario-bible.md): tracks
 * which version of which legal document each user has accepted, so we can
 * require reacceptance whenever a document is materially updated. The
 * document content itself is a product-safe draft — see
 * `prisma/seed.ts`'s `seedLegalDocuments` for the "requires professional
 * legal review" note.
 */
@Injectable()
export class LegalService {
  constructor(private readonly prisma: PrismaService) {}

  /** The most recently published document of a given type. */
  async getLatest(type: LegalDocumentType) {
    const document = await this.prisma.legalDocument.findFirst({
      where: { type },
      orderBy: { publishedAt: 'desc' },
    });
    if (!document) {
      throw new NotFoundException(`No published ${type} document exists yet.`);
    }
    return document;
  }

  /**
   * For each document type, whether the user has accepted the currently
   * latest published version — the onboarding/settings flow uses this to
   * decide whether reacceptance is required.
   */
  async getAcceptanceStatus(userId: string) {
    const types = Object.values(LegalDocumentType);
    const results = await Promise.all(
      types.map(async (type) => {
        const latest = await this.prisma.legalDocument.findFirst({
          where: { type },
          orderBy: { publishedAt: 'desc' },
        });
        if (!latest) {
          return { type, latestVersion: null, hasAcceptedLatest: false };
        }
        const acceptance = await this.prisma.legalAcceptance.findFirst({
          where: { userId, legalDocumentId: latest.id },
        });
        return { type, latestVersion: latest.version, hasAcceptedLatest: Boolean(acceptance) };
      }),
    );
    return results;
  }

  async recordAcceptance(userId: string, legalDocumentId: string, regionCode?: string) {
    const document = await this.prisma.legalDocument.findUnique({
      where: { id: legalDocumentId },
    });
    if (!document) {
      throw new NotFoundException('That legal document does not exist.');
    }

    // Idempotent: re-accepting the same already-accepted version is a
    // no-op rather than piling up duplicate rows.
    const existing = await this.prisma.legalAcceptance.findFirst({
      where: { userId, legalDocumentId },
    });
    if (existing) {
      return existing;
    }

    return this.prisma.legalAcceptance.create({
      data: { userId, legalDocumentId, regionCode },
    });
  }

  listMine(userId: string) {
    return this.prisma.legalAcceptance.findMany({
      where: { userId },
      include: { legalDocument: { select: { type: true, version: true } } },
      orderBy: { acceptedAt: 'desc' },
    });
  }
}
