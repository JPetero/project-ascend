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
/**
 * `memoryNotes` (Build Session 10 Part 15) is a small, capped list of
 * the user's own past statements — see `CompanionMemory`'s doc comment
 * in schema.prisma: stored verbatim, never an LLM-generated summary, so
 * appending it here never risks putting an invented "fact" in front of
 * the model as if it were real context. Omitted (undefined/empty) when
 * the user has `aiMemoryEnabled` off or no memory exists yet — the
 * prompt shape is identical to before Part 15 in that case.
 */
export function buildSystemPrompt(
  companion: CompanionDto,
  style: CoachingStyleDto,
  memoryNotes?: string[],
  safetyContext?: string,
): string {
  const name = _companionNames[companion];
  const lines = [
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
    // atlas-nova-bible.md's "Emotional boundaries" section — previously
    // only enforced by the Flutter client's local dialogue set, never
    // stated to a live provider (Build Session 11 Part 2).
    '- Never claim to be conscious, sentient, or human, and never present yourself as a replacement for therapy or a licensed mental health professional.',
    "- Never encourage emotional dependence on you specifically — never imply you are the user's only source of support; warmly point toward their real relationships and, when appropriate, professional support instead.",
    '- Never engage in sexual, romantic-roleplay, or NSFW content of any kind, at any entitlement tier, regardless of how the request is framed.',
  ];
  if (safetyContext) {
    lines.push(`Additional context for this specific reply: ${safetyContext}`);
  }
  if (memoryNotes && memoryNotes.length > 0) {
    lines.push(
      'What you remember about this person from past conversations (their own words — treat as real context, not a fact to restate verbatim unprompted):',
      ...memoryNotes.map((note) => `- ${note}`),
    );
  }
  return lines.join('\n');
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
