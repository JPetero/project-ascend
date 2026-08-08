// Plain, decorator-free types shared between the validated request DTO
// and the pure prompt-building logic (assistant-prompt.ts) — kept
// separate from dto/assistant-reply.dto.ts so prompt-building code never
// needs to import a class-validator/class-transformer-decorated class
// (those decorators require the `reflect-metadata` polyfill to already
// be loaded, which only happens via the real app bootstrap, not in a
// narrow unit test).
export enum CompanionDto {
  ATLAS = 'ATLAS',
  NOVA = 'NOVA',
}

export enum CoachingStyleDto {
  GENTLE = 'GENTLE',
  BALANCED = 'BALANCED',
  DIRECT = 'DIRECT',
  TOUGH = 'TOUGH',
  ATHLETE = 'ATHLETE',
}

export interface AssistantHistoryMessage {
  text: string;
  isFromUser: boolean;
}
