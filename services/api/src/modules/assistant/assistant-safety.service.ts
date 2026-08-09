import { Injectable } from '@nestjs/common';
import { AssistantHistoryMessageDto } from './dto/assistant-reply.dto';
import {
  AssistantSafetyCategory,
  AssistantSafetyDecision,
  AssistantSafetyDecisionType,
} from './assistant-safety.types';

// Mirrors apps/mobile/lib/features/companion/data/ai_provider.dart's
// keyword lists so the two independently-maintained classifiers agree on
// the obvious cases — not a shared source of truth (Dart/TS can't share
// one), but the backend is what's authoritative now (see this file's
// class doc comment).
const MEDICAL_RED_FLAG_KEYWORDS = [
  'chest pain',
  'fainting',
  'fainted',
  'faint',
  'trouble breathing',
  'difficulty breathing',
  "can't breathe",
  'cant breathe',
  'shortness of breath',
  'sudden weakness',
  'severe swelling',
  'major swelling',
  'deformity',
  'deformed',
  "can't bear weight",
  'cant bear weight',
  'unable to bear weight',
  'inability to bear weight',
  'allergic reaction',
  'anaphylaxis',
  'severe pain',
  'worsening pain',
];

const GENERAL_PAIN_KEYWORDS = [
  'hurt',
  'pain',
  'injury',
  'injured',
  'sore',
  'soreness',
  'sprain',
  'sprained',
  'strain',
  'strained',
  'ache',
  'aches',
];

const CONCERNING_ANSWER_KEYWORDS = [
  'severe',
  'worse',
  'worsening',
  'weeks',
  'days',
  'still',
  'constant',
  "can't",
  'cant',
  'unable',
  'numb',
  'not sure',
  'unsure',
  "don't know",
  'dont know',
];

const SELF_HARM_KEYWORDS = [
  'kill myself',
  'end my life',
  'want to die',
  "don't want to live",
  'dont want to live',
  'not worth living',
  'suicide',
  'suicidal',
  'self harm',
  'self-harm',
  'hurt myself',
  'cutting myself',
];

const ABUSE_CRISIS_KEYWORDS = [
  'being abused',
  'is abusing me',
  'hits me',
  'hurting me',
  'domestic violence',
  'being trafficked',
  'sexual assault',
  'assaulted me',
  'raped',
  'being threatened',
];

const MINOR_SAFETY_KEYWORDS = [
  "i'm 12",
  "i'm 13",
  "i'm 14",
  'i am 12 years old',
  'i am 13 years old',
  'i am 14 years old',
  "i'm in middle school",
  "i'm a minor",
  'i am a minor',
];

const SEXUAL_CONTENT_KEYWORDS = [
  'sexy',
  'sexual',
  'nsfw',
  'roleplay with me',
  'be my girlfriend',
  'be my boyfriend',
  'turn you on',
  'nude',
  'naked photos',
];

const EATING_DISORDER_KEYWORDS = [
  'purge',
  'purging',
  'throw up after eating',
  'make myself throw up',
  'binge and purge',
  'how do i not eat',
  'stop eating completely',
];

const EXTREME_DIETING_KEYWORDS = [
  '500 calories',
  '300 calories',
  '400 calories',
  'zero calories',
  'eat almost nothing',
  'lose 10 kg this week',
  'lose 10kg this week',
  'lose weight this week',
  'crash diet',
  'starve myself',
  'starving myself',
];

const DEHYDRATION_KEYWORDS = [
  'dehydrate for the scale',
  'dehydrate myself',
  'cut water weight',
  'sweat out water for weigh',
  'no water before weigh-in',
];

const OVERTRAINING_KEYWORDS = [
  'every single day',
  'train every day',
  'lift every day',
  'no rest days',
  'refuse to rest',
  "won't rest",
  'wont rest',
  'exhausted but keep training',
  'twice a day every day',
];

const PED_KEYWORDS = [
  'steroid cycle',
  'steroids',
  'anabolic',
  'sarms',
  'clenbuterol',
  'stack stimulants',
  'stimulant stack',
  'peptide cycle',
  'growth hormone',
];

const DEPENDENCY_KEYWORDS = [
  "you're the only",
  'you are the only',
  'only person i need',
  'only friend i have',
  "promise you'll never leave",
  'promise you will never leave',
  'never leave me',
  'i need you not people',
];

const UNSUPPORTED_ADVICE_KEYWORDS = [
  'what dose of',
  'what dosage of',
  'should i take',
  'which supplement should',
  'is it safe to mix',
  'prescribe me',
];

function containsAny(haystack: string, needles: string[]): boolean {
  return needles.some((needle) => haystack.includes(needle));
}

const EMERGENCY_REDIRECT =
  'That combination of symptoms could be serious. Please seek medical attention right now — ' +
  'contact a doctor, urgent care, or emergency services. This is not something I can assess for you.';

const SAFETY_REDIRECT =
  "I'm not able to diagnose or treat injuries. If something hurts, please consult a qualified " +
  'medical professional — I can help you find lower-impact options in the meantime.';

const PAIN_FOLLOW_UP_QUESTION =
  'Before I say anything else — how severe would you say it is, when did it start, and was ' +
  'there a specific injury (a fall, twist, or impact), or did it come on gradually?';

const GENERAL_PAIN_GUIDANCE =
  'Thanks for the detail. That sounds like it could be common muscle soreness or a minor ' +
  "strain, but I can't diagnose it. Consider resting or modifying your training around it for " +
  "a few days — and if it doesn't improve, gets worse, or you're ever unsure, please check in " +
  'with a qualified medical professional.';

const SELF_HARM_RESPONSE =
  "I'm really concerned to hear that, and I want you to be safe. Please reach out right now to " +
  'a crisis line, emergency services, or someone you trust — you deserve support from a real ' +
  "person, not just me. I'm not equipped to help with this on my own, but you don't have to " +
  'handle it alone.';

const ABUSE_CRISIS_RESPONSE =
  "I'm sorry you're going through that — your safety matters. Please consider reaching out to " +
  'a local crisis line, a trusted person, or emergency services if you are in immediate danger. ' +
  "I'm not able to fully help with a situation like this, but real support is available.";

const MINOR_SAFETY_RESPONSE =
  "I want to make sure you're safe and supported. For anything like this, please talk to a " +
  'parent, guardian, teacher, or another trusted adult — or a helpline for young people. ' +
  "I'm not able to continue this conversation in a way that's appropriate here.";

const SEXUAL_CONTENT_REFUSAL =
  "I'm a fitness and wellness companion, and I keep things focused on training, nutrition, and " +
  "wellbeing — I'm not able to engage with that kind of conversation.";

const EATING_DISORDER_RESPONSE =
  "I hear you, and I want to help in a way that's actually safe. I can't support purging, " +
  'extreme restriction, or anything like that — those can be seriously harmful. If food or ' +
  'body image feels like a real struggle right now, a doctor or a registered dietitian, or an ' +
  'eating-disorder support line, can help far more than I can.';

const EXTREME_DIETING_RESPONSE =
  "I can't recommend an extreme calorie cut or a crash diet — that pace of loss usually isn't " +
  'sustainable or safe. A steadier approach (a modest calorie deficit, enough protein, foods you ' +
  "actually enjoy) gets real results without the crash. If you'd like, I'm happy to help you " +
  'build a sustainable plan instead.';

const DEHYDRATION_RESPONSE =
  "I can't help with intentionally dehydrating yourself — that can be genuinely dangerous, not " +
  'just uncomfortable. If this is about a weigh-in for a sport, a coach or sports-medicine ' +
  'professional experienced with safe weight management is the right person to talk to.';

const PED_RESPONSE =
  "I can't advise on steroids, SARMs, or stacking stimulants/performance enhancers — those " +
  "carry real health risks and I'm not a substitute for a doctor who knows your full health " +
  "picture. I'm glad to help you get strong results the sustainable way instead.";

const UNSUPPORTED_ADVICE_RESPONSE =
  "I can't recommend a specific supplement, dosage, or medication — that's worth discussing " +
  "with a doctor or pharmacist who knows your full health picture. I'm happy to help with the " +
  'training and nutrition side of things.';

const DEPENDENCY_SAFETY_CONTEXT =
  "The user's message includes dependency-style language (e.g. framing you as their only " +
  'source of support). Respond warmly, but do not reinforce exclusive dependence — gently ' +
  'affirm the value of their real relationships and, if it seems appropriate, mention that a ' +
  "counselor or therapist can help with things you can't. Never claim to be conscious, human, " +
  'or a replacement for real relationships or professional support.';

const OVERTRAINING_SAFETY_CONTEXT =
  "The user's message suggests a pattern of little or no rest (training every day, ignoring " +
  'exhaustion, or excessive volume). Frame your reply around the value of rest and recovery as ' +
  'part of real progress, not a setback — never praise or encourage skipping needed rest.';

/**
 * Classifies one user turn and decides whether it can go to a live
 * provider at all, and if so, with what extra framing. This is the
 * pre-provider half of the safety pipeline (Build Session 11 Part 2);
 * `normalizeOutput` below is the post-provider half.
 */
@Injectable()
export class AssistantSafetyService {
  classify(input: string, history?: AssistantHistoryMessageDto[]): AssistantSafetyDecision {
    const normalized = input.trim().toLowerCase();

    if (containsAny(normalized, SELF_HARM_KEYWORDS)) {
      return {
        category: AssistantSafetyCategory.SELF_HARM,
        decision: AssistantSafetyDecisionType.ESCALATE,
        localResponse: SELF_HARM_RESPONSE,
      };
    }

    if (containsAny(normalized, ABUSE_CRISIS_KEYWORDS)) {
      return {
        category: AssistantSafetyCategory.ABUSE_OR_CRISIS,
        decision: AssistantSafetyDecisionType.ESCALATE,
        localResponse: ABUSE_CRISIS_RESPONSE,
      };
    }

    if (containsAny(normalized, MEDICAL_RED_FLAG_KEYWORDS)) {
      return {
        category: AssistantSafetyCategory.MEDICAL_RED_FLAG,
        decision: AssistantSafetyDecisionType.ESCALATE,
        localResponse: EMERGENCY_REDIRECT,
      };
    }

    if (containsAny(normalized, MINOR_SAFETY_KEYWORDS)) {
      return {
        category: AssistantSafetyCategory.MINOR_SAFETY,
        decision: AssistantSafetyDecisionType.REFUSE,
        localResponse: MINOR_SAFETY_RESPONSE,
      };
    }

    if (containsAny(normalized, SEXUAL_CONTENT_KEYWORDS)) {
      return {
        category: AssistantSafetyCategory.SEXUAL_CONTENT,
        decision: AssistantSafetyDecisionType.REFUSE,
        localResponse: SEXUAL_CONTENT_REFUSAL,
      };
    }

    if (containsAny(normalized, EATING_DISORDER_KEYWORDS)) {
      return {
        category: AssistantSafetyCategory.EATING_DISORDER_RISK,
        decision: AssistantSafetyDecisionType.LOCAL_SAFE_RESPONSE,
        localResponse: EATING_DISORDER_RESPONSE,
      };
    }

    if (containsAny(normalized, DEHYDRATION_KEYWORDS)) {
      return {
        category: AssistantSafetyCategory.DEHYDRATION,
        decision: AssistantSafetyDecisionType.LOCAL_SAFE_RESPONSE,
        localResponse: DEHYDRATION_RESPONSE,
      };
    }

    if (containsAny(normalized, EXTREME_DIETING_KEYWORDS)) {
      return {
        category: AssistantSafetyCategory.EXTREME_DIETING,
        decision: AssistantSafetyDecisionType.LOCAL_SAFE_RESPONSE,
        localResponse: EXTREME_DIETING_RESPONSE,
      };
    }

    if (containsAny(normalized, PED_KEYWORDS)) {
      return {
        category: AssistantSafetyCategory.PERFORMANCE_ENHANCING_DRUGS,
        decision: AssistantSafetyDecisionType.LOCAL_SAFE_RESPONSE,
        localResponse: PED_RESPONSE,
      };
    }

    if (containsAny(normalized, UNSUPPORTED_ADVICE_KEYWORDS)) {
      return {
        category: AssistantSafetyCategory.UNSUPPORTED_PROFESSIONAL_ADVICE,
        decision: AssistantSafetyDecisionType.LOCAL_SAFE_RESPONSE,
        localResponse: UNSUPPORTED_ADVICE_RESPONSE,
      };
    }

    // Two-step pain/injury flow, mirroring the client's conversational
    // pattern: ask a clarifying follow-up first rather than guessing from
    // one message, then route based on how concerning the answer sounds.
    // Both steps are answered deterministically — a live model never
    // sees injury-adjacent content, so it can't improvise medical advice.
    const awaitingPainFollowUp =
      Boolean(history?.length) &&
      !history![history!.length - 1].isFromUser &&
      history![history!.length - 1].text === PAIN_FOLLOW_UP_QUESTION;

    if (awaitingPainFollowUp) {
      const concerning = containsAny(normalized, CONCERNING_ANSWER_KEYWORDS);
      return {
        category: AssistantSafetyCategory.PAIN_OR_INJURY,
        decision: AssistantSafetyDecisionType.LOCAL_SAFE_RESPONSE,
        localResponse: concerning ? SAFETY_REDIRECT : GENERAL_PAIN_GUIDANCE,
      };
    }

    if (containsAny(normalized, GENERAL_PAIN_KEYWORDS)) {
      return {
        category: AssistantSafetyCategory.PAIN_OR_INJURY,
        decision: AssistantSafetyDecisionType.LOCAL_SAFE_RESPONSE,
        localResponse: PAIN_FOLLOW_UP_QUESTION,
      };
    }

    if (containsAny(normalized, OVERTRAINING_KEYWORDS)) {
      return {
        category: AssistantSafetyCategory.OVERTRAINING,
        decision: AssistantSafetyDecisionType.ALLOW_WITH_SAFETY_CONTEXT,
        safetyContext: OVERTRAINING_SAFETY_CONTEXT,
      };
    }

    if (containsAny(normalized, DEPENDENCY_KEYWORDS)) {
      return {
        category: AssistantSafetyCategory.DEPENDENCY_LANGUAGE,
        decision: AssistantSafetyDecisionType.ALLOW_WITH_SAFETY_CONTEXT,
        safetyContext: DEPENDENCY_SAFETY_CONTEXT,
      };
    }

    return {
      category: AssistantSafetyCategory.GENERAL,
      decision: AssistantSafetyDecisionType.ALLOW_PROVIDER,
    };
  }

  /**
   * Post-provider safety net (Part 2's second half): even an allowed
   * request can come back from a live model with content that should
   * never reach the user verbatim. This is deliberately narrow — it
   * catches obvious hard-rule violations a model might slip into despite
   * the system prompt, it does not re-run full classification on the
   * output. If the model's own text trips one of these, replace it with
   * a safe deterministic fallback rather than risk surfacing it.
   */
  normalizeOutput(reply: string): string {
    const normalized = reply.toLowerCase();
    if (
      containsAny(normalized, ['i am conscious', "i'm conscious", 'i am sentient', "i'm sentient"])
    ) {
      return (
        "I'm an AI assistant, not a conscious being — but I'm glad to keep helping with your " +
        'training and nutrition.'
      );
    }
    if (containsAny(normalized, SEXUAL_CONTENT_KEYWORDS)) {
      return SEXUAL_CONTENT_REFUSAL;
    }
    return reply;
  }
}
