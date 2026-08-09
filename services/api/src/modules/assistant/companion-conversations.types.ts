import { CompanionDto } from './assistant.types';

export interface CompanionChatMessageView {
  id: string;
  isFromUser: boolean;
  text: string;
  createdAt: Date;
}

export interface CompanionConversationSummary {
  id: string;
  companion: CompanionDto;
  title: string | null;
  updatedAt: Date;
  createdAt: Date;
  lastMessagePreview: string | null;
}

export interface CompanionConversationDetail extends CompanionConversationSummary {
  messages: CompanionChatMessageView[];
}
