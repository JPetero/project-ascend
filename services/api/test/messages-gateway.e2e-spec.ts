import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { io, Socket } from 'socket.io-client';
import { AppModule } from '../src/app.module';
import { AllExceptionsFilter } from '../src/common/filters/all-exceptions.filter';
import { ResponseEnvelopeInterceptor } from '../src/common/interceptors/response-envelope.interceptor';
import { PrismaService } from '../src/prisma/prisma.service';
import { resetDatabase } from './utils/reset-database';

describe('Direct Messaging realtime gateway (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let baseUrl: string;
  let tokenA: string;
  let tokenB: string;
  let userIdB: string;
  let clientSocket: Socket;

  beforeAll(async () => {
    const moduleRef: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleRef.createNestApplication();
    app.useGlobalPipes(
      new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }),
    );
    app.useGlobalFilters(new AllExceptionsFilter());
    app.useGlobalInterceptors(new ResponseEnvelopeInterceptor());
    await app.listen(0);
    const address = app.getHttpServer().address();
    baseUrl = `http://127.0.0.1:${address.port}`;

    prisma = app.get(PrismaService);
    await resetDatabase(prisma);

    const register = async (email: string, firstName: string) => {
      const res = await request(app.getHttpServer())
        .post('/auth/register')
        .send({
          firstName,
          email,
          password: 'Str0ngPass!',
          confirmPassword: 'Str0ngPass!',
          acceptedTerms: true,
        })
        .expect(201);
      return {
        token: res.body.data.tokens.accessToken as string,
        id: res.body.data.user.id as string,
      };
    };

    const a = await register('gateway-a@example.com', 'Ada');
    const b = await register('gateway-b@example.com', 'Bea');
    tokenA = a.token;
    tokenB = b.token;
    userIdB = b.id;
  });

  afterAll(async () => {
    clientSocket?.disconnect();
    await resetDatabase(prisma);
    await app.close();
  });

  it('pushes a newly-sent message to a socket joined on that conversation', async () => {
    const started = await request(app.getHttpServer())
      .post('/messages/conversations')
      .set({ Authorization: `Bearer ${tokenA}` })
      .send({ recipientId: userIdB })
      .expect(201);
    const conversationId = started.body.data.id as string;

    clientSocket = io(`${baseUrl}/messages`, {
      auth: { token: tokenB },
      transports: ['websocket'],
      forceNew: true,
    });

    await new Promise<void>((resolve, reject) => {
      const timeout = setTimeout(() => reject(new Error('socket connect timeout')), 8000);
      clientSocket.on('connect', () => {
        clearTimeout(timeout);
        resolve();
      });
      clientSocket.on('connect_error', (error) => {
        clearTimeout(timeout);
        reject(error);
      });
    });

    clientSocket.emit('joinConversation', conversationId);
    // Give the server a beat to process the join before the message fires.
    await new Promise((resolve) => setTimeout(resolve, 300));

    const messageReceived = new Promise<Record<string, unknown>>((resolve, reject) => {
      const timeout = setTimeout(() => reject(new Error('message event timeout')), 8000);
      clientSocket.once('message', (payload: Record<string, unknown>) => {
        clearTimeout(timeout);
        resolve(payload);
      });
    });

    await request(app.getHttpServer())
      .post(`/messages/conversations/${conversationId}/messages`)
      .set({ Authorization: `Bearer ${tokenA}` })
      .send({ body: 'Delivered over the wire' })
      .expect(201);

    const received = await messageReceived;
    expect(received.body).toBe('Delivered over the wire');
  }, 20000);

  it('disconnects a socket that never authenticates', async () => {
    const unauthenticated = io(`${baseUrl}/messages`, {
      transports: ['websocket'],
      forceNew: true,
    });

    const disconnected = new Promise<void>((resolve, reject) => {
      const timeout = setTimeout(() => reject(new Error('disconnect timeout')), 8000);
      unauthenticated.on('disconnect', () => {
        clearTimeout(timeout);
        resolve();
      });
      unauthenticated.on('connect_error', () => {
        clearTimeout(timeout);
        resolve();
      });
    });

    await disconnected;
    unauthenticated.close();
  }, 15000);
});
