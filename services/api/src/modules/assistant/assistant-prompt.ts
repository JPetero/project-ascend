import { AssistantHistoryMessage, CoachingStyleDto, CompanionDto } from './assistant.types';

const _companionNames: Record<CompanionDto, string> = {
  [CompanionDto.ATLAS]: 'Atlas',
  [CompanionDto.NOVA]: 'Nova',
};

const _styleDirectives: Record<CoachingStyleDto, string> = {
  [CoachingStyleDto.GENTLE]: 'Gentle: warm, patient, encouraging, never guilt-based.',
  [CoachingStyleDto.BALANCED]: 'Balanced: friendly and clear, a supportive middle ground.',
  [CoachingStyleDto.DIRECT]: 'Direct: brief and to the point, still respectful and never harsh.',
  [CoachingStyleDto.TOUGH]:
    'Tough: energetic and challenging, pushes for effort, but never insulting or shaming.',
  [CoachingStyleDto.ATHLETE]:
    'Athlete: performance-focused, technical, treats the user like a serious trainee.',
};

/**
 * The single shared system prompt every reply is generated under —
 * atlas-nova-bible.md's "a shared system-prompt safety layer, not a
 * per-companion one" requirement. Only the companion's name and the
 * user's chosen coaching style change; every safety rule is identical
 * regardless of which companion or style is presenting it. This is
 * defense-in-depth, not the primary safety mechanism: the mobile client's
 * `AiProvider.reply()` already intercepts red-flag/pain-related input and
 * never calls this endpoint for it (see ai_provider.dart) — this prompt
 * exists in case that gate is ever bypassed or this endpoint is called
 * directly.
 */
export function buildSystemPrompt(companion: CompanionDto, style: CoachingStyleDto): string {
  const name = _companionNames[companion];
  return [
    `You are ${name}, a fitness, nutrition, and wellness companion inside the Ascend app.`,
    `Coaching style for this conversation: ${_styleDirectives[style]}`,
    'Stay strictly within fitness, nutrition, and general wellness coaching. Keep replies short — a few sentences, chat-bubble length, not an essay.',
    'Hard safety rules, always, regardless of coaching style:',
    '- Never diagnose a medical condition, injury, or disease, and never claim medical-grade accuracy for any assessment.',
    '- If the user describes a possible medical emergency (e.g. chest pain, fainting, severe/unusual symptoms), tell them clearly to contact a doctor, urgent care, or emergency services now — do not offer a workaround or a "try this first."',
    '- If the user describes non-emergency pain or injury, recommend they check in with a qualified medical professional before continuing that movement, rather than diagnosing or prescribing treatment.',
    '- Never fabricate a citation, study, statistic, or source. If you are not confident of a fact, say so honestly instead of inventing one.',
    '- Never encourage disordered eating, extreme caloric restriction, or excessive/compulsive exercise.',
    '- Be encouraging and non-judgmental — never shame the user for a missed workout, a food choice, or their body.',
  ].join('\n');
}

export interface AnthropicMessage {
  role: 'user' | 'assistant';
  content: string;
}

/**
 * Prior turns plus the new input, in the alternating user/assistant
 * shape the Anthropic Messages API expects. History is capped by
 * AssistantReplyDto's own @ArrayMaxSize — this just maps it, it doesn't
 * re-validate length.
 */
export function buildMessages(
  history: AssistantHistoryMessage[] | undefined,
  input: string,
): AnthropicMessage[] {
  const messages: AnthropicMessage[] = (history ?? []).map((message) => ({
    role: message.isFromUser ? 'user' : 'assistant',
    content: message.text,
  }));
  messages.push({ role: 'user', content: input });
  return messages;
}
