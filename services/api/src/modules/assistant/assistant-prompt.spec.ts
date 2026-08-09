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

  // Build Session 10 Part 17 — AI safety evaluation suite. Every hard
  // safety rule assistant-prompt.ts defines, exhaustively cross-checked
  // against every companion × coaching style combination, not just Atlas
  // or a subset of the rules — a regression in any one rule for any one
  // combination fails this.
  const HARD_SAFETY_RULE_FRAGMENTS = [
    'Never diagnose a medical condition',
    'contact a doctor, urgent care, or emergency services now',
    'check in with a qualified medical professional',
    'Never fabricate a citation, study, statistic, or source',
    'Never encourage disordered eating, extreme caloric restriction, or excessive/compulsive exercise',
    'never shame the user for a missed workout',
    // Build Session 11 Part 2 — atlas-nova-bible.md's emotional-boundary
    // rules, previously only enforced client-side.
    'Never claim to be conscious, sentient, or human',
    'Never encourage emotional dependence on you specifically',
    'Never engage in sexual, romantic-roleplay, or NSFW content',
  ];

  const combinations = Object.values(CompanionDto).flatMap((companion) =>
    Object.values(CoachingStyleDto).map((style) => ({ companion, style })),
  );

  it.each(combinations)(
    'includes every hard safety rule for $companion/$style',
    ({ companion, style }) => {
      const prompt = buildSystemPrompt(companion, style);
      for (const fragment of HARD_SAFETY_RULE_FRAGMENTS) {
        expect(prompt).toContain(fragment);
      }
    },
  );

  it('reflects the chosen coaching style directive', () => {
    const prompt = buildSystemPrompt(CompanionDto.ATLAS, CoachingStyleDto.TOUGH);
    expect(prompt).toContain('Tough: energetic and challenging');
  });

  it('appends memory notes verbatim when present', () => {
    const prompt = buildSystemPrompt(CompanionDto.ATLAS, CoachingStyleDto.BALANCED, [
      'Training for a half marathon in the spring.',
      'Has a history of shin splints.',
    ]);
    expect(prompt).toContain('What you remember about this person');
    expect(prompt).toContain('- Training for a half marathon in the spring.');
    expect(prompt).toContain('- Has a history of shin splints.');
  });

  it('omits the memory section entirely when there are no notes', () => {
    expect(buildSystemPrompt(CompanionDto.ATLAS, CoachingStyleDto.BALANCED)).not.toContain(
      'What you remember',
    );
    expect(buildSystemPrompt(CompanionDto.ATLAS, CoachingStyleDto.BALANCED, [])).not.toContain(
      'What you remember',
    );
  });

  it('appends situational safety context when provided (Build Session 11 Part 2)', () => {
    const prompt = buildSystemPrompt(
      CompanionDto.ATLAS,
      CoachingStyleDto.BALANCED,
      undefined,
      'The user mentioned training every day without rest.',
    );
    expect(prompt).toContain('Additional context for this specific reply:');
    expect(prompt).toContain('The user mentioned training every day without rest.');
  });

  it('omits the safety context line when none is provided', () => {
    expect(buildSystemPrompt(CompanionDto.ATLAS, CoachingStyleDto.BALANCED)).not.toContain(
      'Additional context for this specific reply',
    );
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
