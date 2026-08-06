import { NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { LegalDocumentType } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { LegalService } from './legal.service';

describe('LegalService', () => {
  let service: LegalService;
  let prisma: {
    legalDocument: { findFirst: jest.Mock; findUnique: jest.Mock };
    legalAcceptance: { findFirst: jest.Mock; create: jest.Mock; findMany: jest.Mock };
  };

  beforeEach(async () => {
    prisma = {
      legalDocument: { findFirst: jest.fn(), findUnique: jest.fn() },
      legalAcceptance: { findFirst: jest.fn(), create: jest.fn(), findMany: jest.fn() },
    };

    const moduleRef = await Test.createTestingModule({
      providers: [LegalService, { provide: PrismaService, useValue: prisma }],
    }).compile();

    service = moduleRef.get(LegalService);
  });

  it('returns the most recently published document of a type', async () => {
    prisma.legalDocument.findFirst.mockResolvedValue({ id: 'doc-1', version: 'v2' });

    const result = await service.getLatest(LegalDocumentType.TERMS_OF_SERVICE);

    expect(prisma.legalDocument.findFirst).toHaveBeenCalledWith({
      where: { type: LegalDocumentType.TERMS_OF_SERVICE },
      orderBy: { publishedAt: 'desc' },
    });
    expect(result.id).toBe('doc-1');
  });

  it('throws NotFoundException when no document of that type is published', async () => {
    prisma.legalDocument.findFirst.mockResolvedValue(null);

    await expect(service.getLatest(LegalDocumentType.PRIVACY_POLICY)).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('records a new acceptance when the user has not accepted this document before', async () => {
    prisma.legalDocument.findUnique.mockResolvedValue({ id: 'doc-1' });
    prisma.legalAcceptance.findFirst.mockResolvedValue(null);
    prisma.legalAcceptance.create.mockResolvedValue({ id: 'acceptance-1' });

    await service.recordAcceptance('user-1', 'doc-1', 'PH');

    expect(prisma.legalAcceptance.create).toHaveBeenCalledWith({
      data: { userId: 'user-1', legalDocumentId: 'doc-1', regionCode: 'PH' },
    });
  });

  it('is idempotent — does not create a duplicate row for an already-accepted document', async () => {
    prisma.legalDocument.findUnique.mockResolvedValue({ id: 'doc-1' });
    prisma.legalAcceptance.findFirst.mockResolvedValue({ id: 'existing-acceptance' });

    const result = await service.recordAcceptance('user-1', 'doc-1');

    expect(prisma.legalAcceptance.create).not.toHaveBeenCalled();
    expect(result).toEqual({ id: 'existing-acceptance' });
  });

  it('rejects accepting a document that does not exist', async () => {
    prisma.legalDocument.findUnique.mockResolvedValue(null);

    await expect(service.recordAcceptance('user-1', 'missing-doc')).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });
});
