import { Request, Response } from "express";
import Notification from "./notification.model";

export const getNotifications = async (req: Request, res: Response) => {
    try {
        const userId = (req as any).user.userId;
        const { page = 1, limit = 20 } = req.query;
        const notifications = await Notification.find({
            userId,
            isDeleted: false
        })
            .sort({ createdAt: -1 })
            .skip((+page - 1) * +limit)
            .limit(+limit);
        res.json(notifications);
    } catch (error) {
        res.status(500).json({ message: "Get notifications failed", error });
    }
};

export const markAsRead = async (req: Request, res: Response) => {
    try {
        const { id } = req.params;
        const notification = await Notification.findOneAndUpdate(
            { _id: id, userId: (req as any).user.userId },
            { isRead: true },
            { new: true }
        );
        if (!notification) {
            return res.status(404).json({ message: "Notification not found" });
        }
        res.json(notification);
    } catch (error) {
        res.status(500).json({ message: "Mark as read failed", error });
    }
};
export const markAllAsRead = async (req: Request, res: Response) => {
  const userId = (req as any).user.userId;

  await Notification.updateMany(
    { userId, isRead: false },
    { isRead: true }
  );

  res.json({ message: "All marked as read" });
};

export const deleteNotification = async (req: Request, res: Response) => {
    try {
        const { id } = req.params;
        const notification = await Notification.findOneAndUpdate(
            { _id: id, userId: (req as any).user.userId },
            { isDeleted: true, deletedAt: new Date() },
            { new: true }
        );
        if (!notification) {
            return res.status(404).json({ message: "Notification not found" });
        }
        res.json({ message: "Notification deleted" });
    }
    catch (error) {
        res.status(500).json({ message: "Delete notification failed", error });
    }
};

export const deleteAllNotifications = async (req: Request, res: Response) => {
    try {
        const userId = (req as any).user.userId;
        await Notification.updateMany(
            { userId, isDeleted: false },
            { isDeleted: true, deletedAt: new Date() }
        );
        res.json({ message: "All notifications deleted" });
    } catch (error) {
        res.status(500).json({ message: "Delete all notifications failed", error });
    }
};

export const createNotification = async (req: Request, res: Response) => {
    try {
        const { userId, type, title, message, postId, locketId, rideId, senderId } = req.body;
        const notification = new Notification({ userId, type, title, message, postId, locketId, rideId, senderId });
        await notification.save();
        res.status(201).json(notification);
    } catch (error) {
        res.status(500).json({ message: "Create notification failed", error });
    }
};

export const getUnreadCount = async (req: Request, res: Response) => {
    const userId = (req as any).user.userId;

    const count = await Notification.countDocuments({
        userId,
        isRead: false,
        isDeleted: false
    });

    res.json({ count });
};