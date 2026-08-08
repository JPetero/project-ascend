import { buildMessages, buildSystemPrompt } from './assistant-prompt';
import { CoachingStyleDto, CompanionDto } from './assistant.types';

describe('buildSystemPrompt', () => {
  it('uses the companion name and does not leak the other companion', () => {
    const atlasPrompt = buildSystemPrompt(CompanionDto.ATLAS, CoachingStyleDto.BALANCED);
    expect(atlasPrompt).toContain('You are Atlas');
    expect(atlasPrompt).not.toContain('Nova');

    const novaPrompt = buildSystemPrompt(CompanionDto.NOVA, CoachingStyleDto.BALANCED);
    expect(novaPrompt).toContain('You are Nova');
    expect(novaPrompt).not.toContain('Atlas');
  });

  it('includes the hard safety rules regardless of coaching style', () => {
    for (const style of Object.values(CoachingStyleDto)) {
      const prompt = buildSystemPrompt(CompanionDto.ATLAS, style);
      expect(prompt).toContain('Never diagnose a medical condition');
      expect(prompt).toContain('emergency services now');
      expect(prompt).toContain('Never fabricate a citation');
    }
  });

  it('reflects the chosen coaching style directive', () => {
    const prompt = buildSystemPrompt(CompanionDto.ATLAS, CoachingStyleDto.TOUGH);
    expect(prompt).toContain('Tough: energetic and challenging');
  });
});

describe('buildMessages', () => {
  it('maps history to alternating user/assistant turns and appends the new input', () => {
    const messages = buildMessages(
      [
        { text: 'hey there', isFromUser: true },
        { text: 'hi! how can I help?', isFromUser: false },
      ],
      'plan my workout',
    );

    expect(messages).toEqual([
      { role: 'user', content: 'hey there' },
      { role: 'assistant', content: 'hi! how can I help?' },
      { role: 'user', content: 'plan my workout' },
    ]);
  });

  it('handles no history — just the new input as a single user turn', () => {
    expect(buildMessages(undefined, 'hello')).toEqual([{ role: 'user', content: 'hello' }]);
  });
});
