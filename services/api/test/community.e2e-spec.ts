import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { AllExceptionsFilter } from '../src/common/filters/all-exceptions.filter';
import { ResponseEnvelopeInterceptor } from '../src/common/interceptors/response-envelope.interceptor';
import { PrismaService } from '../src/prisma/prisma.service';
import { resetDatabase } from './utils/reset-database';

describe('Community profiles/posts/Reels (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let tokenA: string;
  let tokenB: string;
  let tokenC: string;
  let userIdA: string;
  let userIdB: string;
  let userIdC: string;

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
      return {
        token: res.body.data.tokens.accessToken as string,
        id: res.body.data.user.id as string,
      };
    };

    const a = await register('community-a@example.com', 'Ada');
    const b = await register('community-b@example.com', 'Bea');
    const c = await register('community-c@example.com', 'Cid');
    tokenA = a.token;
    tokenB = b.token;
    tokenC = c.token;
    userIdA = a.id;
    userIdB = b.id;
    userIdC = c.id;
  });

  afterAll(async () => {
    await resetDatabase(prisma);
    await app.close();
  });

  const authA = () => ({ Authorization: `Bearer ${tokenA}` });
  const authB = () => ({ Authorization: `Bearer ${tokenB}` });
  const authC = () => ({ Authorization: `Bearer ${tokenC}` });

  it('upserts and reads a public creator profile, including counts', async () => {
    await request(app.getHttpServer())
      .post('/community/profile')
      .set(authA())
      .send({ displayName: 'Ada the Trainer', bio: 'Strength coach', isTrainer: true })
      .expect(201);

    const viewed = await request(app.getHttpServer())
      .get(`/community/profile/${userIdA}`)
      .set(authB())
      .expect(200);

    expect(viewed.body.data.displayName).toBe('Ada the Trainer');
    expect(viewed.body.data.isTrainer).toBe(true);
    expect(viewed.body.data.followerCount).toBe(0);
    expect(viewed.body.data.isFollowedByViewer).toBe(false);
  });

  it('404s for a profile that was never created', async () => {
    await request(app.getHttpServer())
      .get('/community/profile/00000000-0000-0000-0000-000000000000')
      .set(authA())
      .expect(404);
  });

  it('creates a TEXT post and shows it in the public feed', async () => {
    await request(app.getHttpServer())
      .post('/community/posts')
      .set(authA())
      .send({ caption: 'Hit a new deadlift PR today' })
      .expect(201);

    const feed = await request(app.getHttpServer())
      .get('/community/posts')
      .set(authB())
      .expect(200);

    const found = feed.body.data.data.find(
      (p: { caption: string }) => p.caption === 'Hit a new deadlift PR today',
    );
    expect(found).toBeDefined();
    expect(found.mediaType).toBe('TEXT');
    expect(found.moderationStatus).toBe('APPROVED');
    expect(found.likeCount).toBe(0);
    expect(found.isOwnPost).toBe(false);
  });

  it('rejects a VIDEO ("Reel") post without a mediaUrl', async () => {
    await request(app.getHttpServer())
      .post('/community/posts')
      .set(authA())
      .send({ mediaType: 'VIDEO', caption: 'Missing the video URL' })
      .expect(400);
  });

  it('creates a VIDEO Reel with a caption and it appears with the right media type', async () => {
    const created = await request(app.getHttpServer())
      .post('/community/posts')
      .set(authA())
      .send({
        mediaType: 'VIDEO',
        mediaUrl: 'https://cdn.example.com/reels/reel-1.mp4',
        caption: 'Quick mobility Reel',
        isTrainerContent: true,
      })
      .expect(201);

    expect(created.body.data.mediaType).toBe('VIDEO');
    expect(created.body.data.mediaUrl).toBe('https://cdn.example.com/reels/reel-1.mp4');
    expect(created.body.data.isTrainerContent).toBe(true);
  });

  const VALID_JPEG_BASE64 = Buffer.from([
    0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10, 0x4a, 0x46, 0x49, 0x46,
  ]).toString('base64');

  async function uploadReadyImage(auth: () => Record<string, string>) {
    const initiated = await request(app.getHttpServer())
      .post('/media/uploads')
      .set(auth())
      .send({
        mediaType: 'COMMUNITY_IMAGE',
        originalFilename: 'photo.jpg',
        mimeType: 'image/jpeg',
        sizeBytes: 1000,
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

  it('creates a post from an uploaded Media Platform asset and resolves a real object URL', async () => {
    const mediaAssetId = await uploadReadyImage(authA);

    const created = await request(app.getHttpServer())
      .post('/community/posts')
      .set(authA())
      .send({ mediaType: 'IMAGE', mediaAssetId, caption: 'Uploaded through the Media Platform' })
      .expect(201);

    expect(created.body.data.mediaUrl).toContain('/media/objects/');

    const asset = await request(app.getHttpServer())
      .get(`/media/${mediaAssetId}`)
      .set(authA())
      .expect(200);
    expect(asset.body.data.visibility).toBe('PUBLIC');
  });

  it("404s creating a post from someone else's media asset", async () => {
    const mediaAssetId = await uploadReadyImage(authB);

    await request(app.getHttpServer())
      .post('/community/posts')
      .set(authA())
      .send({ mediaType: 'IMAGE', mediaAssetId, caption: 'Not mine' })
      .expect(404);
  });

  it('rejects creating a post from a media asset that has not finished uploading', async () => {
    const initiated = await request(app.getHttpServer())
      .post('/media/uploads')
      .set(authA())
      .send({
        mediaType: 'COMMUNITY_IMAGE',
        originalFilename: 'photo.jpg',
        mimeType: 'image/jpeg',
        sizeBytes: 1000,
      })
      .expect(201);
    const mediaAssetId = initiated.body.data.mediaAsset.id as string;

    await request(app.getHttpServer())
      .post('/community/posts')
      .set(authA())
      .send({ mediaType: 'IMAGE', mediaAssetId, caption: 'Never finished uploading' })
      .expect(400);
  });

  it('keeps a FOLLOWERS-only post hidden until the viewer follows the author, then visible', async () => {
    const created = await request(app.getHttpServer())
      .post('/community/posts')
      .set(authC())
      .send({ caption: 'Followers-only update', visibility: 'FOLLOWERS' })
      .expect(201);
    const postId = created.body.data.id;

    const beforeFollow = await request(app.getHttpServer())
      .get(`/community/posts/${postId}`)
      .set(authB())
      .expect(404);
    expect(beforeFollow.body.error).toBeDefined();

    await request(app.getHttpServer())
      .post(`/community/follow/${userIdC}`)
      .set(authB())
      .expect(204);

    const afterFollow = await request(app.getHttpServer())
      .get(`/community/posts/${postId}`)
      .set(authB())
      .expect(200);
    expect(afterFollow.body.data.caption).toBe('Followers-only update');

    await request(app.getHttpServer())
      .delete(`/community/follow/${userIdC}`)
      .set(authB())
      .expect(204);
  });

  it('the "Following" feed mode shows only own + followed-author posts, excluding a stranger\'s PUBLIC post', async () => {
    const stranger = await request(app.getHttpServer())
      .post('/community/posts')
      .set(authC())
      .send({ caption: 'A public post from a stranger to the viewer' })
      .expect(201);

    const discover = await request(app.getHttpServer())
      .get('/community/posts')
      .set(authB())
      .expect(200);
    expect(
      discover.body.data.data.some((p: { id: string }) => p.id === stranger.body.data.id),
    ).toBe(true);

    const followingOnly = await request(app.getHttpServer())
      .get('/community/posts')
      .query({ followingOnly: 'true' })
      .set(authB())
      .expect(200);
    expect(
      followingOnly.body.data.data.some((p: { id: string }) => p.id === stranger.body.data.id),
    ).toBe(false);

    await request(app.getHttpServer())
      .post(`/community/follow/${userIdC}`)
      .set(authB())
      .expect(204);

    const followingAfterFollow = await request(app.getHttpServer())
      .get('/community/posts')
      .query({ followingOnly: 'true' })
      .set(authB())
      .expect(200);
    expect(
      followingAfterFollow.body.data.data.some(
        (p: { id: string }) => p.id === stranger.body.data.id,
      ),
    ).toBe(true);

    await request(app.getHttpServer())
      .delete(`/community/follow/${userIdC}`)
      .set(authB())
      .expect(204);
  });

  it('mediaType=VIDEO filters the feed to Reels only (Build Session 10 Part 22)', async () => {
    const reel = await request(app.getHttpServer())
      .post('/community/posts')
      .set(authA())
      .send({
        mediaType: 'VIDEO',
        mediaUrl: 'https://cdn.example.com/reels/reel-filter.mp4',
        caption: 'A reel for the filter test',
      })
      .expect(201);
    const textPost = await request(app.getHttpServer())
      .post('/community/posts')
      .set(authA())
      .send({ caption: 'A plain text post for the filter test' })
      .expect(201);

    const videoOnly = await request(app.getHttpServer())
      .get('/community/posts')
      .query({ mediaType: 'VIDEO' })
      .set(authA())
      .expect(200);

    expect(
      videoOnly.body.data.data.some((p: { id: string }) => p.id === reel.body.data.id),
    ).toBe(true);
    expect(
      videoOnly.body.data.data.some((p: { id: string }) => p.id === textPost.body.data.id),
    ).toBe(false);
    expect(
      videoOnly.body.data.data.every((p: { mediaType: string }) => p.mediaType === 'VIDEO'),
    ).toBe(true);
  });

  it('keeps a PRIVATE post visible only to its own author', async () => {
    const created = await request(app.getHttpServer())
      .post('/community/posts')
      .set(authC())
      .send({ caption: 'Just for me', visibility: 'PRIVATE' })
      .expect(201);
    const postId = created.body.data.id;

    await request(app.getHttpServer()).get(`/community/posts/${postId}`).set(authC()).expect(200);
    await request(app.getHttpServer()).get(`/community/posts/${postId}`).set(authB()).expect(404);
  });

  it('likes and unlikes a post, reflected in the like count and isLikedByViewer', async () => {
    const created = await request(app.getHttpServer())
      .post('/community/posts')
      .set(authA())
      .send({ caption: 'Like me' })
      .expect(201);
    const postId = created.body.data.id;

    await request(app.getHttpServer())
      .post(`/community/posts/${postId}/like`)
      .set(authB())
      .expect(204);
    // Liking twice is idempotent, not an error and not a double count.
    await request(app.getHttpServer())
      .post(`/community/posts/${postId}/like`)
      .set(authB())
      .expect(204);

    const liked = await request(app.getHttpServer())
      .get(`/community/posts/${postId}`)
      .set(authB())
      .expect(200);
    expect(liked.body.data.likeCount).toBe(1);
    expect(liked.body.data.isLikedByViewer).toBe(true);

    await request(app.getHttpServer())
      .delete(`/community/posts/${postId}/like`)
      .set(authB())
      .expect(204);

    const unliked = await request(app.getHttpServer())
      .get(`/community/posts/${postId}`)
      .set(authB())
      .expect(200);
    expect(unliked.body.data.likeCount).toBe(0);
    expect(unliked.body.data.isLikedByViewer).toBe(false);
  });

  it('saves and unsaves a post, and lists saved posts for the saver only', async () => {
    const created = await request(app.getHttpServer())
      .post('/community/posts')
      .set(authA())
      .send({ caption: 'Save this one' })
      .expect(201);
    const postId = created.body.data.id;

    await request(app.getHttpServer())
      .post(`/community/posts/${postId}/save`)
      .set(authB())
      .expect(204);

    const savedByB = await request(app.getHttpServer())
      .get('/community/posts/saved')
      .set(authB())
      .expect(200);
    expect(savedByB.body.data.data.some((p: { id: string }) => p.id === postId)).toBe(true);

    const savedByC = await request(app.getHttpServer())
      .get('/community/posts/saved')
      .set(authC())
      .expect(200);
    expect(savedByC.body.data.data.some((p: { id: string }) => p.id === postId)).toBe(false);

    await request(app.getHttpServer())
      .delete(`/community/posts/${postId}/save`)
      .set(authB())
      .expect(204);
    const afterUnsave = await request(app.getHttpServer())
      .get('/community/posts/saved')
      .set(authB())
      .expect(200);
    expect(afterUnsave.body.data.data.some((p: { id: string }) => p.id === postId)).toBe(false);
  });

  it('adds comments, lists them with author info, and lets the post author moderate any comment', async () => {
    const created = await request(app.getHttpServer())
      .post('/community/posts')
      .set(authA())
      .send({ caption: 'Comment on this' })
      .expect(201);
    const postId = created.body.data.id;

    const comment = await request(app.getHttpServer())
      .post(`/community/posts/${postId}/comments`)
      .set(authB())
      .send({ body: 'Nice work!' })
      .expect(201);
    expect(comment.body.data.body).toBe('Nice work!');

    const list = await request(app.getHttpServer())
      .get(`/community/posts/${postId}/comments`)
      .set(authC())
      .expect(200);
    expect(list.body.data.data).toHaveLength(1);
    expect(list.body.data.data[0].authorId).toBe(userIdB);

    // The bystander (C) may not delete B's comment...
    await request(app.getHttpServer())
      .delete(`/community/comments/${comment.body.data.id}`)
      .set(authC())
      .expect(403);
    // ...but the post's own author (A) may moderate it.
    await request(app.getHttpServer())
      .delete(`/community/comments/${comment.body.data.id}`)
      .set(authA())
      .expect(204);
  });

  it('follows and unfollows, and lists followers/following', async () => {
    await request(app.getHttpServer())
      .post(`/community/follow/${userIdA}`)
      .set(authC())
      .expect(204);

    const followers = await request(app.getHttpServer())
      .get(`/community/follow/${userIdA}/followers`)
      .set(authA())
      .expect(200);
    expect(followers.body.data.data.some((p: { userId: string }) => p.userId === userIdC)).toBe(
      true,
    );

    const following = await request(app.getHttpServer())
      .get(`/community/follow/${userIdC}/following`)
      .set(authA())
      .expect(200);
    expect(following.body.data.data.some((p: { userId: string }) => p.userId === userIdA)).toBe(
      true,
    );

    await request(app.getHttpServer())
      .delete(`/community/follow/${userIdA}`)
      .set(authC())
      .expect(204);
  });

  it('rejects following yourself', async () => {
    await request(app.getHttpServer())
      .post(`/community/follow/${userIdA}`)
      .set(authA())
      .expect(400);
  });

  it('blocking hides the blocked user’s profile and posts, and severs any existing follow', async () => {
    await request(app.getHttpServer())
      .post(`/community/follow/${userIdA}`)
      .set(authB())
      .expect(204);

    const created = await request(app.getHttpServer())
      .post('/community/posts')
      .set(authA())
      .send({ caption: 'Visible before block' })
      .expect(201);
    const postId = created.body.data.id;

    await request(app.getHttpServer()).post(`/community/block/${userIdA}`).set(authB()).expect(204);

    await request(app.getHttpServer())
      .get(`/community/profile/${userIdA}`)
      .set(authB())
      .expect(404);
    await request(app.getHttpServer()).get(`/community/posts/${postId}`).set(authB()).expect(404);

    const feed = await request(app.getHttpServer())
      .get('/community/posts')
      .set(authB())
      .expect(200);
    expect(feed.body.data.data.some((p: { id: string }) => p.id === postId)).toBe(false);

    // The follow B -> A made just before blocking is gone too.
    const followingAfterBlock = await request(app.getHttpServer())
      .get(`/community/follow/${userIdB}/following`)
      .set(authC())
      .expect(200);
    expect(
      followingAfterBlock.body.data.data.some((p: { userId: string }) => p.userId === userIdA),
    ).toBe(false);

    await request(app.getHttpServer())
      .delete(`/community/block/${userIdA}`)
      .set(authB())
      .expect(204);
  });

  it('rejects blocking yourself', async () => {
    await request(app.getHttpServer()).post(`/community/block/${userIdA}`).set(authA()).expect(400);
  });

  it('files a report against a real post and 404s against a made-up one', async () => {
    const created = await request(app.getHttpServer())
      .post('/community/posts')
      .set(authA())
      .send({ caption: 'Reportable' })
      .expect(201);

    const filed = await request(app.getHttpServer())
      .post('/community/reports')
      .set(authB())
      .send({ targetType: 'POST', targetId: created.body.data.id, reason: 'Spam content' })
      .expect(201);
    expect(filed.body.data.status).toBe('OPEN');

    await request(app.getHttpServer())
      .post('/community/reports')
      .set(authB())
      .send({
        targetType: 'POST',
        targetId: '00000000-0000-0000-0000-000000000000',
        reason: 'Spam content',
      })
      .expect(404);
  });

  it('deleting a post removes it from the feed, and only its author may delete it', async () => {
    const created = await request(app.getHttpServer())
      .post('/community/posts')
      .set(authA())
      .send({ caption: 'Temporary post' })
      .expect(201);
    const postId = created.body.data.id;

    await request(app.getHttpServer())
      .delete(`/community/posts/${postId}`)
      .set(authB())
      .expect(403);
    await request(app.getHttpServer())
      .delete(`/community/posts/${postId}`)
      .set(authA())
      .expect(204);
    await request(app.getHttpServer()).get(`/community/posts/${postId}`).set(authA()).expect(404);
  });
});
