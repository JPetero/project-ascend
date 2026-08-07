import { Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  OnGatewayDisconnect,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { AppConfig } from '../../config/configuration';
import { MessagesService } from './messages.service';

/**
 * Realtime delivery layer for Direct Messaging — Build Session 8 Part 8.
 * Purely a push convenience on top of the database-first REST API
 * (messages.controller.ts): every message is created over REST, then
 * this gateway broadcasts it to whichever participant sockets are
 * connected. A client that never connects, or whose socket drops,
 * still sees every message on its next REST poll — nothing here is
 * required for durability or correctness, per the "do not require
 * realtime transport for messages to remain durable" rule.
 */
@WebSocketGateway({ namespace: '/messages', cors: { origin: '*' } })
export class MessagesGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server!: Server;

  private readonly logger = new Logger(MessagesGateway.name);
  private readonly socketUserIds = new Map<string, string>();

  constructor(
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly messagesService: MessagesService,
  ) {}

  async handleConnection(client: Socket): Promise<void> {
    const token =
      (client.handshake.auth?.token as string | undefined) ??
      (client.handshake.query?.token as string | undefined);
    if (!token) {
      client.disconnect(true);
      return;
    }

    try {
      const appConfig = this.configService.get<AppConfig>('app')!;
      const payload = await this.jwtService.verifyAsync<{ sub: string }>(token, {
        secret: appConfig.jwt.accessSecret,
      });
      this.socketUserIds.set(client.id, payload.sub);
      await client.join(`user:${payload.sub}`);
    } catch {
      client.disconnect(true);
    }
  }

  handleDisconnect(client: Socket): void {
    this.socketUserIds.delete(client.id);
  }

  @SubscribeMessage('joinConversation')
  async handleJoinConversation(
    @ConnectedSocket() client: Socket,
    @MessageBody() conversationId: string,
  ): Promise<void> {
    const userId = this.socketUserIds.get(client.id);
    if (!userId) return;
    try {
      // Verifies the caller is actually a participant before letting
      // them subscribe to this conversation's room.
      await this.messagesService.getMessages(userId, conversationId, 1, 1);
      await client.join(`conversation:${conversationId}`);
    } catch (error) {
      this.logger.debug(`Rejected joinConversation for ${userId}: ${error}`);
    }
  }

  /** Called by MessagesController right after a REST-created message is persisted. */
  emitNewMessage(conversationId: string, message: unknown): void {
    this.server?.to(`conversation:${conversationId}`).emit('message', message);
  }
}
