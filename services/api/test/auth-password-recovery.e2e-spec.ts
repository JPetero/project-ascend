import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { AllExceptionsFilter } from '../src/common/filters/all-exceptions.filter';
import { ResponseEnvelopeInterceptor } from '../src/common/interceptors/response-envelope.interceptor';
import {
  EMAIL_PROVIDER,
  EmailDeliveryResult,
  EmailMessage,
  EmailProvider,
} from '../src/modules/email/providers/email-provider.interface';
import { PrismaService } from '../src/prisma/prisma.service';
import { resetDatabase } from './utils/reset-database';

/**
 * A fake EmailProvider that captures every message instead of sending it,
 * so tests can extract the real opaque token from the reset/verification
 * link the same way a user would by clicking the link in their inbox —
 * without ever bypassing the actual token-hashing/lookup path.
 */
class CapturingEmailProvider implements EmailProvider {
  readonly sent: EmailMessage[] = [];

  async send(message: EmailMessage): Promise<EmailDeliveryResult> {
    this.sent.push(message);
    return { delivered: true };
  }
}

function extractToken(message: EmailMessage): string {
  const match = /token=([^&\s"]+)/.exec(message.text);
  if (!match) {
    throw new Error(`No token found in captured email: ${message.text}`);
  }
  return decodeURIComponent(match[1]);
}

describe('Password recovery & email verification (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let emailProvider: CapturingEmailProvider;

  beforeAll(async () => {
    emailProvider = new CapturingEmailProvider();

    const moduleRef: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(EMAIL_PROVIDER)
      .useValue(emailProvider)
      .compile();

    app = moduleRef.createNestApplication();
    app.useGlobalPipes(
      new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }),
    );
    app.useGlobalFilters(new AllExceptionsFilter());
    app.useGlobalInterceptors(new ResponseEnvelopeInterceptor());
    await app.init();

    prisma = app.get(PrismaService);
    await resetDatabase(prisma);
  });

  afterAll(async () => {
    await resetDatabase(prisma);
    await app.close();
  });

  const register = async (email: string) => {
    const res = await request(app.getHttpServer())
      .post('/auth/register')
      .send({
        firstName: 'Ada',
        email,
        password: 'Str0ngPass!',
        confirmPassword: 'Str0ngPass!',
        acceptedTerms: true,
      })
      .expect(201);
    return res.body.data as {
      user: { id: string; emailVerifiedAt: string | null };
      tokens: { accessToken: string; refreshToken: string };
    };
  };

  it('registration issues an unverified account and sends a verification email', async () => {
    const { user } = await register('verify-flow@example.com');
    expect(user.emailVerifiedAt).toBeNull();

    const verificationEmail = emailProvider.sent.find((m) => m.to === 'verify-flow@example.com');
    expect(verificationEmail).toBeDefined();
    expect(verificationEmail!.subject).toContain('Verify');
  });

  it('verify-email confirms the account and rejects reusing the same token', async () => {
    await register('verify-once@example.com');
    const message = emailProvider.sent.find((m) => m.to === 'verify-once@example.com')!;
    const token = extractToken(message);

    await request(app.getHttpServer()).post('/auth/verify-email').send({ token }).expect(200);

    const { body: loginBody } = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: 'verify-once@example.com', password: 'Str0ngPass!' })
      .expect(200);
    expect(loginBody.data.user.emailVerifiedAt).not.toBeNull();

    // Replaying the same (now-used) token must be rejected.
    await request(app.getHttpServer()).post('/auth/verify-email').send({ token }).expect(401);
  });

  it('resend-verification is a no-op for an already-verified account', async () => {
    const { tokens } = await register('resend-verified@example.com');
    const firstMessage = emailProvider.sent.find((m) => m.to === 'resend-verified@example.com')!;
    await request(app.getHttpServer())
      .post('/auth/verify-email')
      .send({ token: extractToken(firstMessage) })
      .expect(200);

    const sentBefore = emailProvider.sent.length;
    await request(app.getHttpServer())
      .post('/auth/resend-verification')
      .set('Authorization', `Bearer ${tokens.accessToken}`)
      .send()
      .expect(200);

    expect(emailProvider.sent.length).toBe(sentBefore);
  });

  it('forgot-password gives the same response whether or not the email exists, and never sends mail for an unknown address', async () => {
    await register('forgot-flow@example.com');
    const sentBefore = emailProvider.sent.length;

    const knownRes = await request(app.getHttpServer())
      .post('/auth/forgot-password')
      .send({ email: 'forgot-flow@example.com' })
      .expect(200);
    const unknownRes = await request(app.getHttpServer())
      .post('/auth/forgot-password')
      .send({ email: 'no-such-account@example.com' })
      .expect(200);

    expect(knownRes.body.data.message).toBe(unknownRes.body.data.message);
    // Exactly one new email was sent — the real account's reset email —
    // never one for the unknown address.
    expect(emailProvider.sent.length).toBe(sentBefore + 1);
    expect(emailProvider.sent[emailProvider.sent.length - 1].to).toBe('forgot-flow@example.com');
  });

  it('reset-password: full round trip, then old password stops working and every session is signed out', async () => {
    const { tokens } = await register('reset-flow@example.com');

    await request(app.getHttpServer())
      .post('/auth/forgot-password')
      .send({ email: 'reset-flow@example.com' })
      .expect(200);
    const resetEmail = emailProvider.sent.find(
      (m) => m.to === 'reset-flow@example.com' && m.subject.includes('Reset'),
    )!;
    const token = extractToken(resetEmail);

    await request(app.getHttpServer())
      .post('/auth/reset-password')
      .send({ token, newPassword: 'NewStr0ngPass!', confirmNewPassword: 'NewStr0ngPass!' })
      .expect(200);

    // Old password no longer works.
    await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: 'reset-flow@example.com', password: 'Str0ngPass!' })
      .expect(401);
    // New password works.
    await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: 'reset-flow@example.com', password: 'NewStr0ngPass!' })
      .expect(200);

    // The pre-reset access token's refresh token was revoked by logoutAll —
    // the session from before the reset can no longer refresh.
    await request(app.getHttpServer())
      .post('/auth/refresh')
      .send({ refreshToken: tokens.refreshToken })
      .expect(401);

    // Reusing the already-used reset token is rejected.
    await request(app.getHttpServer())
      .post('/auth/reset-password')
      .send({ token, newPassword: 'AnotherPass1!', confirmNewPassword: 'AnotherPass1!' })
      .expect(401);
  });

  it('reset-password rejects mismatched new passwords and an invalid token', async () => {
    await request(app.getHttpServer())
      .post('/auth/reset-password')
      .send({
        token: 'nonsense-token',
        newPassword: 'NewStr0ngPass!',
        confirmNewPassword: 'Different1!',
      })
      .expect(409);

    await request(app.getHttpServer())
      .post('/auth/reset-password')
      .send({
        token: 'nonsense.token',
        newPassword: 'NewStr0ngPass!',
        confirmNewPassword: 'NewStr0ngPass!',
      })
      .expect(401);
  });

  it('change-password requires the correct current password and updates the hash', async () => {
    const { tokens } = await register('change-flow@example.com');
    const auth = { Authorization: `Bearer ${tokens.accessToken}` };

    await request(app.getHttpServer())
      .post('/auth/change-password')
      .set(auth)
      .send({
        currentPassword: 'wrong-password',
        newPassword: 'ChangedPass1!',
        confirmNewPassword: 'ChangedPass1!',
      })
      .expect(401);

    await request(app.getHttpServer())
      .post('/auth/change-password')
      .set(auth)
      .send({
        currentPassword: 'Str0ngPass!',
        newPassword: 'ChangedPass1!',
        confirmNewPassword: 'ChangedPass1!',
      })
      .expect(200);

    await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: 'change-flow@example.com', password: 'ChangedPass1!' })
      .expect(200);
  });

  it('delete-account requires the correct password, signs out every session, and frees the email for reuse', async () => {
    const { tokens } = await register('delete-flow@example.com');
    const auth = { Authorization: `Bearer ${tokens.accessToken}` };

    await request(app.getHttpServer())
      .delete('/auth/account')
      .set(auth)
      .send({ password: 'wrong-password' })
      .expect(401);

    await request(app.getHttpServer())
      .delete('/auth/account')
      .set(auth)
      .send({ password: 'Str0ngPass!' })
      .expect(200);

    // The account can no longer log in...
    await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: 'delete-flow@example.com', password: 'Str0ngPass!' })
      .expect(401);

    // ...and its pre-deletion access token is dead too (refresh revoked).
    await request(app.getHttpServer())
      .post('/auth/refresh')
      .send({ refreshToken: tokens.refreshToken })
      .expect(401);

    // The now-anonymized email is free for a brand new registration.
    await request(app.getHttpServer())
      .post('/auth/register')
      .send({
        firstName: 'Ada',
        email: 'delete-flow@example.com',
        password: 'Str0ngPass!',
        confirmPassword: 'Str0ngPass!',
        acceptedTerms: true,
      })
      .expect(201);
  });
});
