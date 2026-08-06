import { ConflictException, Injectable } from '@nestjs/common';
import { AuthIdentity, AuthProvider } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';

/**
 * Scenario 2/3 (see packages/docs/product/user-scenario-bible.md): lets a
 * single Ascend account be reached through more than one sign-in provider
 * (email today; Google/Apple once live credentials exist) without ever
 * silently merging two established accounts. Every existing user already
 * has an EMAIL row from the backfill migration, so this service is the
 * uniform lookup path regardless of provider.
 */
@Injectable()
export class AuthIdentitiesService {
  constructor(private readonly prisma: PrismaService) {}

  findByProviderSubject(provider: AuthProvider, providerSubject: string) {
    return this.prisma.authIdentity.findUnique({
      where: { provider_providerSubject: { provider, providerSubject } },
    });
  }

  listForUser(userId: string) {
    return this.prisma.authIdentity.findMany({
      where: { userId },
      orderBy: { createdAt: 'asc' },
    });
  }

  /**
   * Links a new provider identity to an *already-authenticated* Ascend
   * user — the caller must have proven ownership of `userId` via a valid
   * bearer token before calling this (never link based on email match
   * alone). Rejects with a conflict if the identity is already linked to
   * a different user, since one external identity can never belong to two
   * Ascend accounts (unique index on provider + providerSubject).
   */
  async linkIdentity(
    userId: string,
    provider: AuthProvider,
    providerSubject: string,
    providerEmail?: string,
  ): Promise<AuthIdentity> {
    const existing = await this.findByProviderSubject(provider, providerSubject);
    if (existing) {
      if (existing.userId === userId) {
        return this.prisma.authIdentity.update({
          where: { id: existing.id },
          data: { lastUsedAt: new Date(), providerEmail: providerEmail ?? existing.providerEmail },
        });
      }
      throw new ConflictException(
        'This account is already linked to a different Ascend user. Sign in with it directly instead.',
      );
    }

    return this.prisma.authIdentity.create({
      data: { userId, provider, providerSubject, providerEmail },
    });
  }
}
