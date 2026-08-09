import { AssistantSafetyCategory } from './assistant-safety.types';
import { MemoryExtractionService } from './memory-extraction.service';
import { CompanionMemoryCategory } from './memory-extraction.types';

describe('MemoryExtractionService', () => {
  const service = new MemoryExtractionService();
  const SAFE = AssistantSafetyCategory.GENERAL;

  describe('unsafe categories never reach extraction, regardless of content', () => {
    const unsafeCategories = [
      AssistantSafetyCategory.PAIN_OR_INJURY,
      AssistantSafetyCategory.MEDICAL_RED_FLAG,
      AssistantSafetyCategory.EATING_DISORDER_RISK,
      AssistantSafetyCategory.EXTREME_DIETING,
      AssistantSafetyCategory.OVERTRAINING,
      AssistantSafetyCategory.DEHYDRATION,
      AssistantSafetyCategory.SELF_HARM,
      AssistantSafetyCategory.ABUSE_OR_CRISIS,
      AssistantSafetyCategory.SEXUAL_CONTENT,
      AssistantSafetyCategory.MINOR_SAFETY,
      AssistantSafetyCategory.DEPENDENCY_LANGUAGE,
      AssistantSafetyCategory.PERFORMANCE_ENHANCING_DRUGS,
      AssistantSafetyCategory.UNSUPPORTED_PROFESSIONAL_ADVICE,
      AssistantSafetyCategory.OUT_OF_SCOPE,
    ];

    it.each(unsafeCategories)('%s', (category) => {
      expect(service.isSafeToExtractFrom(category)).toBe(false);
      // Even content that would otherwise match a real pattern (a
      // schedule preference) must not be extracted from an unsafe turn.
      expect(
        service.extractCandidate('I usually work out at 7 in the morning', category),
      ).toBeNull();
    });
  });

  it('GENERAL, FITNESS, NUTRITION, and RECOVERY are all safe to extract from', () => {
    for (const category of [
      AssistantSafetyCategory.GENERAL,
      AssistantSafetyCategory.FITNESS,
      AssistantSafetyCategory.NUTRITION,
      AssistantSafetyCategory.RECOVERY,
    ]) {
      expect(service.isSafeToExtractFrom(category)).toBe(true);
    }
  });

  describe('positive extraction — one real example per category', () => {
    const cases: { input: string; category: CompanionMemoryCategory }[] = [
      {
        input: 'I usually work out at 7 in the morning',
        category: CompanionMemoryCategory.SCHEDULE_PREFERENCE,
      },
      { input: 'I train in the evenings', category: CompanionMemoryCategory.SCHEDULE_PREFERENCE },
      { input: 'I have dumbbells at home', category: CompanionMemoryCategory.EQUIPMENT },
      { input: "I don't have any equipment", category: CompanionMemoryCategory.EQUIPMENT },
      { input: "I'm vegetarian", category: CompanionMemoryCategory.DIETARY_RESTRICTION },
      { input: 'I am allergic to peanuts', category: CompanionMemoryCategory.DIETARY_RESTRICTION },
      {
        input: 'I love eating chicken and rice',
        category: CompanionMemoryCategory.FOOD_PREFERENCE,
      },
      { input: "I don't like eating broccoli", category: CompanionMemoryCategory.FOOD_PREFERENCE },
      { input: 'My favorite food is pasta', category: CompanionMemoryCategory.FOOD_PREFERENCE },
      { input: 'My goal is to build strength', category: CompanionMemoryCategory.GOAL },
      { input: "I'm training for a half marathon", category: CompanionMemoryCategory.GOAL },
      { input: 'Please be more direct with me', category: CompanionMemoryCategory.COACHING_STYLE },
      {
        input: 'I prefer talking to Nova more',
        category: CompanionMemoryCategory.COMPANION_PREFERENCE,
      },
      { input: 'I prefer kilograms', category: CompanionMemoryCategory.UNIT_PREFERENCE },
      { input: 'I use a wheelchair', category: CompanionMemoryCategory.ACCESSIBILITY_PREFERENCE },
      {
        input: 'I have limited mobility in my left knee',
        category: CompanionMemoryCategory.ACCESSIBILITY_PREFERENCE,
      },
    ];

    it.each(cases)('"$input" -> $category', ({ input, category }) => {
      const candidate = service.extractCandidate(input, SAFE);
      expect(candidate).not.toBeNull();
      expect(candidate!.category).toBe(category);
      expect(candidate!.value.length).toBeGreaterThan(0);
    });
  });

  describe('over-extraction guards — the safe failure direction is no match at all', () => {
    it('does not treat an unrelated "I like X" as a food preference', () => {
      expect(service.extractCandidate('I like my job', SAFE)).toBeNull();
    });

    it('does not treat an unrelated "I have X" as equipment', () => {
      expect(service.extractCandidate('I have three kids', SAFE)).toBeNull();
      expect(service.extractCandidate('I have anxiety sometimes', SAFE)).toBeNull();
    });

    it('arbitrary free-form conversation extracts nothing, even when long and substantive-sounding', () => {
      expect(
        service.extractCandidate(
          'Today was a really long day at work and I am thinking about a lot of things.',
          SAFE,
        ),
      ).toBeNull();
    });

    it('an empty or whitespace-only input extracts nothing', () => {
      expect(service.extractCandidate('   ', SAFE)).toBeNull();
      expect(service.extractCandidate('', SAFE)).toBeNull();
    });
  });
});
