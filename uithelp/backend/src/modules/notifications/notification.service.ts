import Notification from "./notification.model";

interface CreateNotifOptions {
  userId: string;
  type: "match" | "comment" | "reaction" | "ride_join";
  title: string;
  message?: string;
  senderId?: string;
  postId?: string;
  locketId?: string;
  rideId?: string;
}

export const createNotification = async (opts: CreateNotifOptions) => {
  try {
    // Không tạo thông báo tự gửi cho chính mình
    if (opts.senderId && opts.senderId === opts.userId) return null;

    const notif = await Notification.create(opts);
    return notif;
  } catch (err) {
    console.error("[Notification] create failed:", err);
    return null;
  }
};
