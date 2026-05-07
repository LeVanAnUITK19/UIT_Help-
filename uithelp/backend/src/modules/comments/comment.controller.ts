import { Request, Response } from "express";
import Comment from "./comment.model";
import Post from "../posts/post.model";
import User from "../auth/auth.model";
import { io } from "../../server";
import { sendPush } from "../../utils/sendPushNotification";
import { createNotification } from "../notifications/notification.service";

export const createComment = async (req: Request, res: Response) => {
    try {
        const { content, postId } = req.body;
        const userId = (req as any).user.userId;
        const user = await User.findById(userId);

        const postExists = await Post.findById(postId);
        if (!postExists) return res.status(400).json({ message: "Không tìm thấy bài post" });

        const comment = await Comment.create({ postId, userId, userName: user?.name, content });
        await Post.findByIdAndUpdate(postId, { $inc: { commentCount: 1 } });
        io.to(postId).emit("new_comment", comment);

        // Gửi push cho chủ bài nếu người comment không phải chủ bài
        if (postExists.userId.toString() !== userId) {
          const postOwner = await User.findById(postExists.userId);
          if (postOwner?.fcmToken) {
            await sendPush(
              postOwner.fcmToken,
              "💬 Bình luận mới",
              `${user?.name ?? "Ai đó"} đã bình luận vào bài của bạn`,
              { type: "comment", postId }
            );
          }
          // Tạo internal notification
          await createNotification({
            userId: postExists.userId.toString(),
            senderId: userId,
            type: "comment",
            title: "💬 Bình luận mới",
            message: `${user?.name ?? "Ai đó"} đã bình luận vào bài của bạn`,
            postId,
          });
        }

        res.status(200).json(comment);
    } catch (error) {
        res.status(500).json({ message: "Tạo comment thất bại", error });
    }
};

export const getComment = async (req: Request, res: Response) => {
    try {
        const limit = 10;
        const { cursor } = req.query;
        const { postId } = req.params;

        const filter: any = { isDeleted: false, postId };
        if (cursor) filter._id = { $lt: cursor };
       

        const comments = await Comment.find(filter).sort({ _id: -1 }).limit(limit);
        const nextCursor = comments.length === limit ? comments[comments.length - 1]._id : null;

        res.json({ comments, nextCursor });
    } catch (error) {
        res.status(500).json({ message: "Lấy comment thất bại", error });
    }
};

export const deleteComment = async (req: Request, res: Response) => {
    try {
        const userId = (req as any).user.userId;
        const { id } = req.params;

        const comment = await Comment.findOne({ _id: id, isDeleted: false });
        if (!comment) return res.status(404).json({ message: "Không tìm thấy comment" });
        if (comment.userId !== userId) return res.status(403).json({ message: "Không có quyền" });

        comment.isDeleted = true;
        comment.deletedAt = new Date();
        await comment.save();
        await Post.findByIdAndUpdate(comment.postId, { $inc: { commentCount: -1 } });
        res.json({ message: "Xóa comment thành công" });
    } catch (error) {
        res.status(500).json({ message: "Xóa comment thất bại", error });
    }
};
