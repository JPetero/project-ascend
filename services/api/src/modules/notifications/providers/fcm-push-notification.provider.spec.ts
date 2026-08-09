import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../../prisma/prisma.service';
import { FcmPushNotificationProvider } from './fcm-push-notification.provider';

describe('FcmPushNotificationProvider', () => {
  const buildConfigService = (push: { fcmServiceAccountJson?: string; fcmProjectId?: string }) =>
    ({ get: () => push }) as unknown as ConfigService;

  it('honestly reports not-configured instead of pretending to deliver when unset', async () => {
    const prisma = {
      pushDeviceToken: { findMany: jest.fn(), deleteMany: jest.fn() },
    } as unknown as PrismaService;
    const provider = new FcmPushNotificationProvider(
      buildConfigService({ fcmServiceAccountJson: undefined, fcmProjectId: undefined }),
      prisma,
    );

    const result = await provider.send('user-1', { title: 'Title', body: 'Body' });

    expect(result).toEqual({ delivered: false, failureReason: 'No push provider configured.' });
    expect(prisma.pushDeviceToken.findMany as jest.Mock).not.toHaveBeenCalled();
  });

  it('honestly reports not-configured when only one of the two required values is set', async () => {
    const prisma = {
      pushDeviceToken: { findMany: jest.fn(), deleteMany: jest.fn() },
    } as unknown as PrismaService;
    const provider = new FcmPushNotificationProvider(
      buildConfigService({
        fcmServiceAccountJson: '{"client_email":"x"}',
        fcmProjectId: undefined,
      }),
      prisma,
    );

    const result = await provider.send('user-1', { title: 'Title', body: 'Body' });

    expect(result.delivered).toBe(false);
    expect(result.failureReason).toBe('No push provider configured.');
  });

  it('reports no registered device without attempting a network call', async () => {
    const findMany = jest.fn().mockResolvedValue([]);
    const prisma = {
      pushDeviceToken: { findMany, deleteMany: jest.fn() },
    } as unknown as PrismaService;
    const provider = new FcmPushNotificationProvider(
      buildConfigService({
        fcmServiceAccountJson: '{"client_email":"x","private_key":"y"}',
        fcmProjectId: 'ascend-app',
      }),
      prisma,
    );

    const result = await provider.send('user-1', { title: 'Title', body: 'Body' });

    expect(findMany).toHaveBeenCalledWith({ where: { userId: 'user-1' } });
    expect(result).toEqual({
      delivered: false,
      failureReason: 'No registered device for this user.',
    });
  });
});
