import admin from '../config/firebase';

export const sendPush = async (fcmToken: string, title: string, body: string, data?: Record<string, string>) => {
  if (!fcmToken) return;
  try {
    await admin.messaging().send({
      token: fcmToken,
      notification: { title, body },
      data,
    });
  } catch (err) {
    console.error('FCM error:', err);
  }
};
