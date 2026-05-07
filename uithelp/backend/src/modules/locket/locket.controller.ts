import { Request, Response } from "express";
import mongoose from "mongoose";
import { Locket, LocketReaction, LocketComment } from "./locket.model";
import User from "../auth/auth.model";
import cloudinary from "../../config/cloudinary";
import streamifier from "streamifier";
import { sendPush } from "../../utils/sendPushNotification";
import { createNotification } from "../notifications/notification.service";

const uploadToCloudinary = (buffer: Buffer): Promise<string> => {
    return new Promise((resolve, reject) => {
        const stream = cloudinary.uploader.upload_stream(
            { folder: "uit_help" },
            (error, result) => {
                if (error || !result) return reject(error);
                resolve(result.secure_url);
            }
        );
        streamifier.createReadStream(buffer).pipe(stream);
    });
};

// ─── Locket CRUD ────────────────────────────────────────────────────────────

export const createLocket = async (req: Request, res: Response) => {
    try {
        const { caption } = req.body;
        const userId = (req as any).user.userId;

        if (!req.file) return res.status(400).json({ message: "Không có ảnh" });

        const user = await User.findById(userId);
        const imageUrl = await uploadToCloudinary(req.file.buffer);

        const locket = await Locket.create({
            userId,
            userName: user?.name,
            imageUrl,
            caption,
        });

        res.status(201).json(locket);
    } catch (error) {
        res.status(500).json({ message: "Tạo Locket thất bại", error });
    }
};

export const getLockets = async (req: Request, res: Response) => {
    try {
        const limit = 10;
        const { cursor } = req.query;
        const filter: any = { isDeleted: false };
        if (cursor) filter._id = { $lt: cursor as string };

        const lockets = await Locket.find(filter).sort({ _id: -1 }).limit(limit);
        const nextCursor = lockets.length === limit ? lockets[lockets.length - 1]._id : null;

        res.json({ lockets, nextCursor });
    } catch (error) {
        res.status(500).json({ message: "Lấy danh sách Locket thất bại", error });
    }
};

export const getMyLockets = async (req: Request, res: Response) => {
    try {
        const userId = (req as any).user.userId;
        const limit = 10;
        const { cursor } = req.query;
        const filter: any = { isDeleted: false, userId };
        if (cursor) filter._id = { $lt: cursor as string };

        const lockets = await Locket.find(filter).sort({ _id: -1 }).limit(limit);
        const nextCursor = lockets.length === limit ? lockets[lockets.length - 1]._id : null;

        res.json({ lockets, nextCursor });
    } catch (error) {
        res.status(500).json({ message: "Lấy Locket của tôi thất bại", error });
    }
};

export const deleteLocket = async (req: Request, res: Response) => {
    try {
        const userId = (req as any).user.userId;
        const { id } = req.params;

        const locket = await Locket.findOne({ _id: id, isDeleted: false });
        if (!locket) return res.status(404).json({ message: "Không tìm thấy Locket" });
        if (locket.userId.toString() !== userId) return res.status(403).json({ message: "Không có quyền" });

        locket.isDeleted = true;
        locket.deletedAt = new Date();
        await locket.save();

        res.json({ message: "Xóa Locket thành công" });
    } catch (error) {
        res.status(500).json({ message: "Xóa Locket thất bại", error });
    }
};

// ─── Reactions ───────────────────────────────────────────────────────────────

export const reactToLocket = async (req: Request, res: Response) => {
    try {
        const userId = (req as any).user.userId;
        const id = req.params.id as string;
        const { type } = req.body;

        const locket = await Locket.findOne({ _id: id, isDeleted: false });
        if (!locket) return res.status(404).json({ message: "Không tìm thấy Locket" });

        const user = await User.findById(userId);

        const existing = await LocketReaction.findOne({ locketId: new mongoose.Types.ObjectId(id), userId });
        if (existing) {
            if (existing.type === type) {
                // toggle off
                await existing.deleteOne();
                await Locket.findByIdAndUpdate(id, { $inc: { reactionsCount: -1 } });
                return res.json({ message: "Đã bỏ reaction" });
            }
            existing.type = type;
            await existing.save();
            return res.json(existing);
        }

        const reaction = await LocketReaction.create({
            locketId: id,
            userId,
            userName: user?.name,
            type,
        });
        await Locket.findByIdAndUpdate(id, { $inc: { reactionsCount: 1 } });

        // Gửi push cho chủ locket nếu người react không phải chủ
        if (locket.userId.toString() !== userId) {
            const locketOwner = await User.findById(locket.userId);
            if (locketOwner?.fcmToken) {
                await sendPush(
                    locketOwner.fcmToken,
                    "❤️ Locket của bạn có react mới",
                    `${user?.name ?? "Ai đó"} đã react locket của bạn`,
                    { type: "locket_react", locketId: id }
                );
            }
            await createNotification({
                userId: locket.userId.toString(),
                senderId: userId,
                type: "reaction",
                title: "❤️ React mới trên Locket",
                message: `${user?.name ?? "Ai đó"} đã react locket của bạn`,
                locketId: id,
            });
        }

        res.status(201).json(reaction);
    } catch (error) {
        res.status(500).json({ message: "React Locket thất bại", error });
    }
};

export const getReactionsOfLocket = async (req: Request, res: Response) => {
    try {
        const id = req.params.id as string;
        const reactions = await LocketReaction.find({ locketId: new mongoose.Types.ObjectId(id), isDeleted: false });
        res.json(reactions);
    } catch (error) {
        res.status(500).json({ message: "Lấy reactions thất bại", error });
    }
};

// ─── Comments ────────────────────────────────────────────────────────────────

export const commentOnLocket = async (req: Request, res: Response) => {
    try {
        const userId = (req as any).user.userId;
        const id = req.params.id as string;
        const { content } = req.body;

        const locket = await Locket.findOne({ _id: id, isDeleted: false });
        if (!locket) return res.status(404).json({ message: "Không tìm thấy Locket" });

        const user = await User.findById(userId);

        const comment = await LocketComment.create({
            locketId: id,
            userId,
            userName: user?.name,
            content,
        });

        // Gửi push cho chủ locket nếu người comment không phải chủ
        if (locket.userId.toString() !== userId) {
            const locketOwner = await User.findById(locket.userId);
            if (locketOwner?.fcmToken) {
                await sendPush(
                    locketOwner.fcmToken,
                    "💬 Bình luận mới trên Locket",
                    `${user?.name ?? "Ai đó"} đã bình luận locket của bạn`,
                    { type: "locket_comment", locketId: id }
                );
            }
            await createNotification({
                userId: locket.userId.toString(),
                senderId: userId,
                type: "comment",
                title: "💬 Bình luận mới trên Locket",
                message: `${user?.name ?? "Ai đó"} đã bình luận locket của bạn`,
                locketId: id,
            });
        }

        res.status(201).json(comment);
    } catch (error) {
        res.status(500).json({ message: "Bình luận thất bại", error });
    }
};

export const getCommentsOfLocket = async (req: Request, res: Response) => {
    try {
        const id = req.params.id as string;
        const comments = await LocketComment.find({ locketId: new mongoose.Types.ObjectId(id) }).sort({ createdAt: -1 });
        res.json(comments);
    } catch (error) {
        res.status(500).json({ message: "Lấy bình luận thất bại", error });
    }
};
