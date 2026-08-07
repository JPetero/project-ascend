import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { AllExceptionsFilter } from '../src/common/filters/all-exceptions.filter';
import { ResponseEnvelopeInterceptor } from '../src/common/interceptors/response-envelope.interceptor';
import { PrismaService } from '../src/prisma/prisma.service';
import { resetDatabase } from './utils/reset-database';

// A tiny but real JPEG signature followed by filler bytes — enough for
// the file-signature check without needing a real fixture image on disk.
const VALID_JPEG_BASE64 = Buffer.from([
  0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10, 0x4a, 0x46, 0x49, 0x46, 0x00, 0x01,
]).toString('base64');
const NOT_A_JPEG_BASE64 = Buffer.from('definitely not an image', 'ascii').toString('base64');

describe('Media Platform (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let tokenA: string;
  let tokenB: string;
  let adminToken: string;

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
    await app.init();

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
      return res.body.data.tokens.accessToken as string;
    };

    tokenA = await register('media-a@example.com', 'Ada');
    tokenB = await register('media-b@example.com', 'Bea');
    adminToken = await register('media-admin@example.com', 'Cam');
    await prisma.user.update({
      where: { email: 'media-admin@example.com' },
      data: { role: 'ADMIN' },
    });
  });

  afterAll(async () => {
    await resetDatabase(prisma);
    await app.close();
  });

  const authA = () => ({ Authorization: `Bearer ${tokenA}` });
  const authB = () => ({ Authorization: `Bearer ${tokenB}` });
  const authAdmin = () => ({ Authorization: `Bearer ${adminToken}` });

  async function uploadAndComplete(auth: () => Record<string, string>, base64 = VALID_JPEG_BASE64) {
    const initiated = await request(app.getHttpServer())
      .post('/media/uploads')
      .set(auth())
      .send({
        mediaType: 'PROFILE_IMAGE',
        originalFilename: 'photo.jpg',
        mimeType: 'image/jpeg',
        sizeBytes: 1000,
        width: 200,
        height: 200,
      })
      .expect(201);

    const mediaAssetId = initiated.body.data.mediaAsset.id as string;

    await request(app.getHttpServer())
      .post(`/media/uploads/${mediaAssetId}/local-bytes`)
      .set(auth())
      .send({ base64 })
      .expect(201);

    return mediaAssetId;
  }

  it('rejects a disallowed MIME type for the media type', async () => {
    await request(app.getHttpServer())
      .post('/media/uploads')
      .set(authA())
      .send({
        mediaType: 'PROFILE_IMAGE',
        originalFilename: 'clip.mp4',
        mimeType: 'video/mp4',
        sizeBytes: 1000,
      })
      .expect(400);
  });

  it('completes a full local-dev upload lifecycle and marks the asset READY/APPROVED', async () => {
    const mediaAssetId = await uploadAndComplete(authA);

    const fetched = await request(app.getHttpServer())
      .get(`/media/${mediaAssetId}`)
      .set(authA())
      .expect(200);

    expect(fetched.body.data.processingState).toBe('READY');
    expect(fetched.body.data.moderationState).toBe('APPROVED');
  });

  it('rejects local-dev bytes whose signature does not match the declared MIME type', async () => {
    const initiated = await request(app.getHttpServer())
      .post('/media/uploads')
      .set(authA())
      .send({
        mediaType: 'PROFILE_IMAGE',
        originalFilename: 'photo.jpg',
        mimeType: 'image/jpeg',
        sizeBytes: 1000,
      })
      .expect(201);
    const mediaAssetId = initiated.body.data.mediaAsset.id as string;

    await request(app.getHttpServer())
      .post(`/media/uploads/${mediaAssetId}/local-bytes`)
      .set(authA())
      .send({ base64: NOT_A_JPEG_BASE64 })
      .expect(400);
  });

  it('404s a private asset for a user who does not own it', async () => {
    const mediaAssetId = await uploadAndComplete(authA);

    await request(app.getHttpServer()).get(`/media/${mediaAssetId}`).set(authB()).expect(404);
  });

  it('becomes visible to another user once made PUBLIC', async () => {
    const mediaAssetId = await uploadAndComplete(authA);

    await request(app.getHttpServer())
      .patch(`/media/${mediaAssetId}/visibility`)
      .set(authA())
      .send({ visibility: 'PUBLIC' })
      .expect(200);

    await request(app.getHttpServer()).get(`/media/${mediaAssetId}`).set(authB()).expect(200);
  });

  it("404s setting visibility on someone else's asset rather than 403ing", async () => {
    const mediaAssetId = await uploadAndComplete(authA);

    await request(app.getHttpServer())
      .patch(`/media/${mediaAssetId}/visibility`)
      .set(authB())
      .send({ visibility: 'PUBLIC' })
      .expect(404);
  });

  it("lists only the caller's own assets", async () => {
    await uploadAndComplete(authA);

    const listed = await request(app.getHttpServer()).get('/media/mine').set(authB()).expect(200);

    expect((listed.body.data as Array<{ id: string }>).every((a) => a.id !== undefined)).toBe(true);
  });

  it('deletes an owned asset and it no longer resolves', async () => {
    const mediaAssetId = await uploadAndComplete(authA);

    await request(app.getHttpServer()).delete(`/media/${mediaAssetId}`).set(authA()).expect(200);

    await request(app.getHttpServer()).get(`/media/${mediaAssetId}`).set(authA()).expect(404);
  });

  it('reports a media asset and an admin can act on it to remove it', async () => {
    const mediaAssetId = await uploadAndComplete(authA);
    await request(app.getHttpServer())
      .patch(`/media/${mediaAssetId}/visibility`)
      .set(authA())
      .send({ visibility: 'PUBLIC' })
      .expect(200);

    const reported = await request(app.getHttpServer())
      .post(`/media/${mediaAssetId}/report`)
      .set(authB())
      .send({ reason: 'This looks like a stolen photo.' })
      .expect(201);
    const reportId = reported.body.data.id as string;

    const actioned = await request(app.getHttpServer())
      .patch(`/admin/community-reports/${reportId}`)
      .set(authAdmin())
      .send({ status: 'ACTIONED', removeContent: true })
      .expect(200);
    expect(actioned.body.data.status).toBe('ACTIONED');

    const removedAsset = await request(app.getHttpServer())
      .get(`/media/${mediaAssetId}`)
      .set(authA())
      .expect(200);
    expect(removedAsset.body.data.moderationState).toBe('REMOVED');
  });

  it('403s a non-admin trying to action a media report', async () => {
    const mediaAssetId = await uploadAndComplete(authA);
    const reported = await request(app.getHttpServer())
      .post(`/media/${mediaAssetId}/report`)
      .set(authB())
      .send({ reason: 'inappropriate' })
      .expect(201);

    await request(app.getHttpServer())
      .patch(`/admin/community-reports/${reported.body.data.id}`)
      .set(authB())
      .send({ status: 'ACTIONED', removeContent: true })
      .expect(403);
  });
});
