import { AssistantService } from './assistant.service';
import { CompanionMemoryService } from './companion-memory.service';
import { AiReplyProvider } from './providers/ai-reply-provider.interface';
import { CoachingStyleDto, CompanionDto } from './assistant.types';
import { PrismaService } from '../../prisma/prisma.service';

function buildService(options?: {
  provider?: Partial<AiReplyProvider>;
  aiMemoryEnabled?: boolean | null;
  memoryNotes?: string[];
  remember?: jest.Mock;
}) {
  const generateReply = jest.fn().mockResolvedValue('Nice work today!');
  const provider: AiReplyProvider = {
    isConfigured: true,
    generateReply,
    ...options?.provider,
  };
  const prisma = {
    preference: {
      findUnique: jest
        .fn()
        .mockResolvedValue(
          options?.aiMemoryEnabled === null
            ? null
            : { aiMemoryEnabled: options?.aiMemoryEnabled ?? true },
        ),
    },
  } as unknown as PrismaService;
  const getNotes = jest.fn().mockResolvedValue(options?.memoryNotes ?? []);
  const remember = options?.remember ?? jest.fn().mockResolvedValue(undefined);
  const clear = jest.fn().mockResolvedValue(undefined);
  const memory = { getNotes, remember, clear } as unknown as CompanionMemoryService;

  const service = new AssistantService(provider, prisma, memory);
  return { service, generateReply, prisma, getNotes, remember, clear };
}

const dto = {
  input: 'plan my workout',
  companion: CompanionDto.ATLAS,
  style: CoachingStyleDto.BALANCED,
};

describe('AssistantService', () => {
  it('delegates isConfigured to whichever AiReplyProvider was injected', () => {
    const { service } = buildService({ provider: { isConfigured: true } });
    expect(service.isConfigured).toBe(true);
  });

  it('reports not configured when the injected provider is not', () => {
    const { service } = buildService({ provider: { isConfigured: false } });
    expect(service.isConfigured).toBe(false);
  });

  it('reply() passes the dto and current memory notes to the provider and returns its result', async () => {
    const { service, generateReply } = buildService({
      memoryNotes: ['Training for a 10k.'],
    });

    const reply = await service.reply(dto, 'user-1');

    expect(generateReply).toHaveBeenCalledWith(dto, ['Training for a 10k.']);
    expect(reply).toBe('Nice work today!');
  });

  it('records the input as a new memory note after a successful reply when memory is enabled', async () => {
    const { service, remember } = buildService({ aiMemoryEnabled: true });

    await service.reply(dto, 'user-1');

    expect(remember).toHaveBeenCalledWith('user-1', dto.input);
  });

  it('never reads or writes memory when aiMemoryEnabled is false', async () => {
    const { service, generateReply, getNotes, remember } = buildService({
      aiMemoryEnabled: false,
    });

    await service.reply(dto, 'user-1');

    expect(getNotes).not.toHaveBeenCalled();
    expect(remember).not.toHaveBeenCalled();
    expect(generateReply).toHaveBeenCalledWith(dto, []);
  });

  it('treats a missing Preference row as memory enabled, matching the schema default', async () => {
    const { service, remember } = buildService({ aiMemoryEnabled: null });

    await service.reply(dto, 'user-1');

    expect(remember).toHaveBeenCalledWith('user-1', dto.input);
  });

  it('a failed memory write never fails the reply itself', async () => {
    const { service } = buildService({
      aiMemoryEnabled: true,
      remember: jest.fn().mockRejectedValue(new Error('db down')),
    });

    await expect(service.reply(dto, 'user-1')).resolves.toBe('Nice work today!');
  });

  it('getMemory() delegates to CompanionMemoryService.getNotes', async () => {
    const { service, getNotes } = buildService({ memoryNotes: ['a fact'] });

    await expect(service.getMemory('user-1')).resolves.toEqual(['a fact']);
    expect(getNotes).toHaveBeenCalledWith('user-1');
  });

  it('clearMemory() delegates to CompanionMemoryService.clear', async () => {
    const { service, clear } = buildService();

    await service.clearMemory('user-1');

    expect(clear).toHaveBeenCalledWith('user-1');
  });
});
