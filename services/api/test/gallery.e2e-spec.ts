import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { AllExceptionsFilter } from '../src/common/filters/all-exceptions.filter';
import { ResponseEnvelopeInterceptor } from '../src/common/interceptors/response-envelope.interceptor';
import { PrismaService } from '../src/prisma/prisma.service';
import { resetDatabase } from './utils/reset-database';

const VALID_JPEG_BASE64 = Buffer.from([
  0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10, 0x4a, 0x46, 0x49, 0x46, 0x00, 0x01,
]).toString('base64');

describe('Gallery (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let tokenA: string;
  let tokenB: string;

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

    tokenA = await register('gallery-a@example.com', 'Ada');
    tokenB = await register('gallery-b@example.com', 'Bea');
  });

  afterAll(async () => {
    await resetDatabase(prisma);
    await app.close();
  });

  const authA = () => ({ Authorization: `Bearer ${tokenA}` });
  const authB = () => ({ Authorization: `Bearer ${tokenB}` });

  async function uploadAndComplete(auth: () => Record<string, string>) {
    const initiated = await request(app.getHttpServer())
      .post('/media/uploads')
      .set(auth())
      .send({
        mediaType: 'PROGRESS_PHOTO',
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
      .send({ base64: VALID_JPEG_BASE64 })
      .expect(201);

    return mediaAssetId;
  }

  async function createAlbum(auth: () => Record<string, string>, body: Record<string, unknown>) {
    const res = await request(app.getHttpServer())
      .post('/gallery/albums')
      .set(auth())
      .send(body)
      .expect(201);
    return res.body.data.id as string;
  }

  it('creates a private-by-default album', async () => {
    const res = await request(app.getHttpServer())
      .post('/gallery/albums')
      .set(authA())
      .send({ name: 'My Progress' })
      .expect(201);

    expect(res.body.data.visibility).toBe('PRIVATE');
    expect(res.body.data.category).toBe('PRIVATE');
  });

  it('adds a media item to an album with a pose tag and weight note', async () => {
    const albumId = await createAlbum(authA, { name: 'Progress', category: 'PROGRESS' });
    const mediaAssetId = await uploadAndComplete(authA);

    const res = await request(app.getHttpServer())
      .post(`/gallery/albums/${albumId}/media`)
      .set(authA())
      .send({ mediaAssetId, poseTag: 'FRONT', weightNote: '72kg' })
      .expect(201);

    expect(res.body.data.poseTag).toBe('FRONT');
    expect(res.body.data.weightNote).toBe('72kg');
    expect(res.body.data.url).toEqual(expect.any(String));

    const album = await request(app.getHttpServer())
      .get(`/gallery/albums/${albumId}`)
      .set(authA())
      .expect(200);
    expect(album.body.data.media).toHaveLength(1);
  });

  it("404s adding another user's media asset to your own album", async () => {
    const albumId = await createAlbum(authA, { name: 'Progress' });
    const foreignAssetId = await uploadAndComplete(authB);

    await request(app.getHttpServer())
      .post(`/gallery/albums/${albumId}/media`)
      .set(authA())
      .send({ mediaAssetId: foreignAssetId })
      .expect(404);
  });

  it("404s reaching into another user's album entirely", async () => {
    const albumId = await createAlbum(authA, { name: 'Private stuff' });

    await request(app.getHttpServer()).get(`/gallery/albums/${albumId}`).set(authB()).expect(404);
  });

  it('setting gallery media as avatar updates the Community profile avatar', async () => {
    await request(app.getHttpServer())
      .post('/community/profile')
      .set(authA())
      .send({ displayName: 'Ada' })
      .expect(201);

    const albumId = await createAlbum(authA, { name: 'Avatars' });
    const mediaAssetId = await uploadAndComplete(authA);
    const added = await request(app.getHttpServer())
      .post(`/gallery/albums/${albumId}/media`)
      .set(authA())
      .send({ mediaAssetId })
      .expect(201);
    const galleryMediaId = added.body.data.id as string;

    await request(app.getHttpServer())
      .post(`/gallery/media/${galleryMediaId}/set-avatar`)
      .set(authA())
      .expect(201);

    const meRes = await request(app.getHttpServer()).get('/auth/me').set(authA()).expect(200);
    const userId = meRes.body.data.id as string;

    const profile = await request(app.getHttpServer())
      .get(`/community/profile/${userId}`)
      .set(authA())
      .expect(200);
    expect(profile.body.data.avatarUrl).toEqual(expect.any(String));
  });

  it('removing gallery media deletes the underlying asset only once nothing else references it', async () => {
    const albumId = await createAlbum(authA, { name: 'Solo item' });
    const mediaAssetId = await uploadAndComplete(authA);
    const added = await request(app.getHttpServer())
      .post(`/gallery/albums/${albumId}/media`)
      .set(authA())
      .send({ mediaAssetId })
      .expect(201);
    const galleryMediaId = added.body.data.id as string;

    await request(app.getHttpServer())
      .delete(`/gallery/media/${galleryMediaId}`)
      .set(authA())
      .expect(200);

    // The asset had no other usage, so it is now soft-deleted and no
    // longer resolvable — same "not found" the Media Platform's own
    // tests assert for a deleted asset.
    await request(app.getHttpServer()).get(`/media/${mediaAssetId}`).set(authA()).expect(404);
  });

  it('deleting an album never deletes a MediaAsset still shared to Community', async () => {
    const albumId = await createAlbum(authA, { name: 'Shared source' });
    const mediaAssetId = await uploadAndComplete(authA);
    await request(app.getHttpServer())
      .post(`/gallery/albums/${albumId}/media`)
      .set(authA())
      .send({ mediaAssetId })
      .expect(201);

    // Share the same underlying asset into a Community post.
    await request(app.getHttpServer())
      .post('/community/posts')
      .set(authA())
      .send({ mediaType: 'IMAGE', mediaAssetId, visibility: 'PUBLIC' })
      .expect(201);

    await request(app.getHttpServer())
      .delete(`/gallery/albums/${albumId}`)
      .set(authA())
      .expect(200);

    // Still resolvable — the Community post is still using it.
    await request(app.getHttpServer()).get(`/media/${mediaAssetId}`).set(authA()).expect(200);
  });

  it('rejects setting an avatar before a Community profile exists', async () => {
    await request(app.getHttpServer())
      .post('/auth/register')
      .send({
        firstName: 'Cam',
        email: 'gallery-c@example.com',
        password: 'Str0ngPass!',
        confirmPassword: 'Str0ngPass!',
        acceptedTerms: true,
      })
      .expect(201);
    const loginRes = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: 'gallery-c@example.com', password: 'Str0ngPass!' })
      .expect(200);
    const tokenC = loginRes.body.data.tokens.accessToken as string;
    const authC = () => ({ Authorization: `Bearer ${tokenC}` });

    const albumId = await createAlbum(authC, { name: 'No profile yet' });
    const mediaAssetId = await uploadAndComplete(authC);
    const added = await request(app.getHttpServer())
      .post(`/gallery/albums/${albumId}/media`)
      .set(authC())
      .send({ mediaAssetId })
      .expect(201);

    await request(app.getHttpServer())
      .post(`/gallery/media/${added.body.data.id}/set-avatar`)
      .set(authC())
      .expect(400);
  });
});
