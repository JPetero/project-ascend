import { Injectable } from '@nestjs/common';
import { AssistantSafetyCategory } from './assistant-safety.types';
import { CompanionMemoryCategory, MemoryCandidate } from './memory-extraction.types';

/**
 * Replaces the original (Build Session 10 Part 15) "any message over 12
 * characters gets saved verbatim" heuristic. That rule had no concept of
 * *what* it was saving — an emotional crisis disclosure, a private
 * medical symptom, or a throwaway complaint about a family argument was
 * exactly as "rememberable" as a stated equipment preference, because
 * length was the only signal.
 *
 * This service only ever returns one of `CompanionMemoryCategory`'s ten
 * allowed categories (workout/equipment/schedule/food/dietary/goal/
 * coaching-style/companion/unit/accessibility preferences) — there is no
 * "other" or "general" bucket, so nothing free-form can slip through by
 * construction. `AssistantService` additionally never calls this at all
 * unless `AssistantSafetyService.classify()` already put the turn in one
 * of the categories checked in `isSafeToExtractFrom` below — the
 * exclusion list matters more than the allowlist here: self-harm,
 * abuse/crisis, sexual content, minor safety, eating-disorder risk,
 * extreme dieting, dehydration, PEDs, pain/injury, dependency language,
 * and unsupported-professional-advice content is never even offered to
 * this extractor, regardless of what patterns it contains.
 *
 * Deterministic pattern matching, not an LLM summarization step — same
 * "never invent a fact" principle the rest of this pipeline follows
 * (assistant-prompt.ts, brave-search-research-provider.ts). Missing a
 * real preference is the safe failure direction for a privacy feature;
 * over-extracting is not, so these patterns are intentionally narrow.
 */
@Injectable()
export class MemoryExtractionService {
  private static readonly UNSAFE_CATEGORIES: ReadonlySet<AssistantSafetyCategory> = new Set([
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
  ]);

  isSafeToExtractFrom(safetyCategory: AssistantSafetyCategory): boolean {
    return !MemoryExtractionService.UNSAFE_CATEGORIES.has(safetyCategory);
  }

  extractCandidate(input: string, safetyCategory: AssistantSafetyCategory): MemoryCandidate | null {
    if (!this.isSafeToExtractFrom(safetyCategory)) return null;

    const trimmed = input.trim();
    if (trimmed.length === 0) return null;

    for (const rule of RULES) {
      const match = rule.pattern.exec(trimmed);
      if (match) {
        const value = rule.value(match).trim();
        if (value.length > 0 && value.length <= 200) {
          return { category: rule.category, value };
        }
      }
    }
    return null;
  }
}

interface Rule {
  category: CompanionMemoryCategory;
  pattern: RegExp;
  value: (match: RegExpMatchArray) => string;
}

const capitalize = (s: string) => s.charAt(0).toUpperCase() + s.slice(1);

const RULES: Rule[] = [
  // --- SCHEDULE_PREFERENCE ---
  {
    category: CompanionMemoryCategory.SCHEDULE_PREFERENCE,
    pattern:
      /\bi (?:usually |normally |typically )?(?:work ?out|train|exercise) (?:at|around) ([\w\s:]+?(?:am|pm|morning|afternoon|evening|night))\b/i,
    value: (m) => `Works out at ${m[1].trim()}.`,
  },
  {
    category: CompanionMemoryCategory.SCHEDULE_PREFERENCE,
    pattern:
      /\bi (?:usually |normally |typically )?(?:work ?out|train|exercise) (?:in the|on) (mornings?|afternoons?|evenings?|weekends?|weekdays?)\b/i,
    value: (m) => `Prefers to train ${m[1].toLowerCase()}.`,
  },

  // --- EQUIPMENT ---
  // Deliberately anchored to an equipment vocabulary rather than a blind
  // "I have X" catch-all — an unanchored version would just as happily
  // extract "I have anxiety" or "I have three kids" as "equipment,"
  // which is exactly the over-extraction this service exists to avoid.
  {
    category: CompanionMemoryCategory.EQUIPMENT,
    pattern:
      /\bi (?:only )?have (?:a |an |some )?(dumbbells?|kettlebells?|resistance bands?|a barbell|barbells?|a bench|weight plates?|a squat rack|a power rack|a pull-?up bar|a treadmill|an? exercise bike|a yoga mat|a home gym|full gym access|gym access)\b/i,
    value: (m) => `Has access to: ${m[1].trim()}.`,
  },
  {
    category: CompanionMemoryCategory.EQUIPMENT,
    pattern: /\bi (?:don'?t|do not) have (?:any |access to )?(?:equipment|weights|a gym)\b/i,
    value: () => 'No equipment / bodyweight only.',
  },

  // --- DIETARY_RESTRICTION (checked before FOOD_PREFERENCE — more specific) ---
  {
    category: CompanionMemoryCategory.DIETARY_RESTRICTION,
    pattern:
      /\bi(?:'m| am) (vegetarian|vegan|pescatarian|gluten[\s-]?free|dairy[\s-]?free|lactose intolerant|keto|halal|kosher)\b/i,
    value: (m) => capitalize(m[1].toLowerCase()) + '.',
  },
  {
    category: CompanionMemoryCategory.DIETARY_RESTRICTION,
    pattern: /\bi(?:'m| am) allergic to ([\w\s]+?)(?:\.|,|$)/i,
    value: (m) => `Allergic to ${m[1].trim()}.`,
  },

  // --- FOOD_PREFERENCE ---
  // Requires an explicit "eating"/food-context word rather than a bare
  // "I like X" — the same over-extraction risk as EQUIPMENT above ("I
  // like my job" is not a food preference).
  {
    category: CompanionMemoryCategory.FOOD_PREFERENCE,
    pattern: /\bi (?:really )?(like|love|enjoy) eating ([\w\s]+?)(?:\.|,|$)/i,
    value: (m) => `Likes eating ${m[2].trim()}.`,
  },
  {
    category: CompanionMemoryCategory.FOOD_PREFERENCE,
    pattern: /\bi (?:don'?t|do not) like eating ([\w\s]+?)(?:\.|,|$)/i,
    value: (m) => `Dislikes eating ${m[1].trim()}.`,
  },
  {
    category: CompanionMemoryCategory.FOOD_PREFERENCE,
    pattern: /\bmy favorite food is ([\w\s]+?)(?:\.|,|$)/i,
    value: (m) => `Favorite food: ${m[1].trim()}.`,
  },

  // --- GOAL ---
  {
    category: CompanionMemoryCategory.GOAL,
    pattern: /\bmy goal is to ([\w\s]+?)(?:\.|,|$)/i,
    value: (m) => `Goal: ${m[1].trim()}.`,
  },
  {
    category: CompanionMemoryCategory.GOAL,
    pattern: /\bi'?m training for (?:an? )?([\w\s]+?)(?:\.|,|$)/i,
    value: (m) => `Training for: ${m[1].trim()}.`,
  },

  // --- COACHING_STYLE ---
  {
    category: CompanionMemoryCategory.COACHING_STYLE,
    pattern: /\bplease be more (gentle|direct|tough|encouraging|straightforward) with me\b/i,
    value: (m) => `Prefers a more ${m[1].toLowerCase()} coaching style.`,
  },

  // --- COMPANION_PREFERENCE ---
  {
    category: CompanionMemoryCategory.COMPANION_PREFERENCE,
    pattern: /\bi (?:prefer|like) (?:talking to |chatting with )?(atlas|nova) (?:more|better)\b/i,
    value: (m) => `Prefers talking with ${capitalize(m[1].toLowerCase())}.`,
  },

  // --- UNIT_PREFERENCE ---
  {
    category: CompanionMemoryCategory.UNIT_PREFERENCE,
    pattern: /\bi (?:prefer|use) (kilograms|kg|pounds|lbs|miles|kilometers|km)\b/i,
    value: (m) => `Prefers ${m[1].toLowerCase()}.`,
  },

  // --- ACCESSIBILITY_PREFERENCE ---
  {
    category: CompanionMemoryCategory.ACCESSIBILITY_PREFERENCE,
    pattern: /\bi use a wheelchair\b/i,
    value: () => 'Uses a wheelchair.',
  },
  {
    category: CompanionMemoryCategory.ACCESSIBILITY_PREFERENCE,
    pattern: /\bi (?:am|'m) hard of hearing\b/i,
    value: () => 'Hard of hearing.',
  },
  {
    category: CompanionMemoryCategory.ACCESSIBILITY_PREFERENCE,
    pattern: /\bi have limited mobility(?: in my ([\w\s]+?))?(?:\.|,|$)/i,
    value: (m) => (m[1] ? `Limited mobility in ${m[1].trim()}.` : 'Has limited mobility.'),
  },
];
