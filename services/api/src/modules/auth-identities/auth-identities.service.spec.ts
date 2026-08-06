import { ConflictException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { AuthProvider } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { AuthIdentitiesService } from './auth-identities.service';

describe('AuthIdentitiesService', () => {
  let service: AuthIdentitiesService;
  let prisma: {
    authIdentity: {
      findUnique: jest.Mock;
      findMany: jest.Mock;
      create: jest.Mock;
      update: jest.Mock;
    };
  };

  beforeEach(async () => {
    prisma = {
      authIdentity: {
        findUnique: jest.fn(),
        findMany: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
      },
    };

    const moduleRef = await Test.createTestingModule({
      providers: [AuthIdentitiesService, { provide: PrismaService, useValue: prisma }],
    }).compile();

    service = moduleRef.get(AuthIdentitiesService);
  });

  it('creates a new identity when none exists for that provider + subject', async () => {
    prisma.authIdentity.findUnique.mockResolvedValue(null);
    prisma.authIdentity.create.mockResolvedValue({ id: 'identity-1' });

    await service.linkIdentity('user-1', AuthProvider.GOOGLE, 'google-sub-1', 'ada@example.com');

    expect(prisma.authIdentity.create).toHaveBeenCalledWith({
      data: {
        userId: 'user-1',
        provider: AuthProvider.GOOGLE,
        providerSubject: 'google-sub-1',
        providerEmail: 'ada@example.com',
      },
    });
  });

  it('re-links (touches lastUsedAt) when the identity already belongs to the same user', async () => {
    prisma.authIdentity.findUnique.mockResolvedValue({
      id: 'identity-1',
      userId: 'user-1',
      providerEmail: 'old@example.com',
    });
    prisma.authIdentity.update.mockResolvedValue({ id: 'identity-1' });

    await service.linkIdentity('user-1', AuthProvider.GOOGLE, 'google-sub-1');

    expect(prisma.authIdentity.update).toHaveBeenCalledWith(
      expect.objectContaining({ where: { id: 'identity-1' } }),
    );
    expect(prisma.authIdentity.create).not.toHaveBeenCalled();
  });

  it('never merges accounts — rejects linking an identity already owned by a different user', async () => {
    prisma.authIdentity.findUnique.mockResolvedValue({ id: 'identity-1', userId: 'someone-else' });

    await expect(
      service.linkIdentity('user-1', AuthProvider.APPLE, 'apple-sub-1'),
    ).rejects.toBeInstanceOf(ConflictException);
    expect(prisma.authIdentity.create).not.toHaveBeenCalled();
    expect(prisma.authIdentity.update).not.toHaveBeenCalled();
  });

  it('lists all identities linked to a user, oldest first', async () => {
    prisma.authIdentity.findMany.mockResolvedValue([]);

    await service.listForUser('user-1');

    expect(prisma.authIdentity.findMany).toHaveBeenCalledWith({
      where: { userId: 'user-1' },
      orderBy: { createdAt: 'asc' },
    });
  });
});
