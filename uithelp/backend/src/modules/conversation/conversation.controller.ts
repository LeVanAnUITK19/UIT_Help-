import { Request, Response } from "express";
import Conversation from "./conversation.model";
import Message from "./message.model";
import User from "../auth/auth.model";
import { io } from "../../server";
import { sendPush } from "../../utils/sendPushNotification";

interface ConversationLean {
  _id: any;
  participants: string[];
  lastMessage: string;
  lastMessageAt: Date;
  unreadCount: Record<string, number>;
}

// Helper: kiểm tra user có trong conversation không
const isParticipant = (participants: string[], userId: string): boolean =>
  participants.map(String).includes(userId);

// ── GET /conversations ────────────────────────────────────────────────────────
export const getConversations = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.userId;
    const conversations = await Conversation.find({
      participants: userId,
    }).sort({ lastMessageAt: -1 });
    res.json(conversations);
  } catch (error) {
    res.status(500).json({ message: "Get conversations failed", error });
  }
};

// ── POST /conversations ───────────────────────────────────────────────────────
export const getOrCreateConversation = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.userId;
    const { targetUserId } = req.body;

    if (!targetUserId) {
      return res.status(400).json({ message: "targetUserId là bắt buộc" });
    }
    if (targetUserId === userId) {
      return res.status(400).json({ message: "Không thể chat với chính mình" });
    }

    const targetUser = await User.findById(targetUserId).select("name");
    if (!targetUser) {
      return res.status(404).json({ message: "Người dùng không tồn tại" });
    }

    let conversation = await Conversation.findOne({
      participants: { $all: [userId, targetUserId], $size: 2 },
    });

    if (!conversation) {
      conversation = await Conversation.create({
        participants: [userId, targetUserId],
        lastMessage: "",
        lastMessageAt: new Date(),
        unreadCount: {},
      });
    }

    res.json(conversation);
  } catch (error) {
    res.status(500).json({ message: "Get or create conversation failed", error });
  }
};

// ── GET /conversations/:conversationId/messages ───────────────────────────────
export const getMessages = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.userId;
    const { conversationId } = req.params;
    const cursor = req.query.cursor as string | undefined;
    const limit = parseInt((req.query.limit as string) ?? "30", 10);

    const conversation = await Conversation.findById(conversationId).lean() as ConversationLean | null;
    if (!conversation) {
      return res.status(404).json({ message: "Conversation không tồn tại" });
    }
    if (!isParticipant(conversation.participants, userId)) {
      return res.status(403).json({ message: "Không có quyền truy cập" });
    }

    const filter: any = { conversationId, isDeleted: false };
    if (cursor) filter._id = { $lt: cursor };

    const messages = await Message.find(filter)
      .sort({ _id: -1 })
      .limit(limit);

    const nextCursor = messages.length === limit
      ? messages[messages.length - 1]._id
      : null;

    res.json({ messages: messages.reverse(), nextCursor });
  } catch (error) {
    res.status(500).json({ message: "Get messages failed", error });
  }
};

// ── POST /conversations/:conversationId/messages ──────────────────────────────
export const sendMessage = async (req: Request, res: Response) => {
  try {
    const senderId = (req as any).user.userId;
    const { conversationId } = req.params;
    const { content, type = "text" } = req.body;

    if (!content || !content.trim()) {
      return res.status(400).json({ message: "Nội dung không được trống" });
    }

    const conversation = await Conversation.findById(conversationId).lean() as ConversationLean | null;
    if (!conversation) {
      return res.status(404).json({ message: "Conversation không tồn tại" });
    }
    if (!isParticipant(conversation.participants, senderId)) {
      return res.status(403).json({ message: "Không có quyền gửi tin nhắn" });
    }

    const msg = new Message({
      conversationId,
      senderId,
      content: content.trim(),
      type: type as "text" | "image",
    });
    const message = await msg.save();

    // Tìm receiverId
    const receiverId = conversation.participants.find((p) => p !== senderId);

    // Lấy unreadCount hiện tại của receiver
    const currentUnread: number = conversation.unreadCount?.[receiverId!] ?? 0;

    await Conversation.findByIdAndUpdate(conversationId, {
      lastMessage: content.trim(),
      lastMessageAt: new Date(),
      [`unreadCount.${receiverId}`]: currentUnread + 1,
    });

    // Realtime
    io.to(conversationId).emit("new_message", message);

    // Push notification
    if (receiverId) {
      const receiver = await User.findById(receiverId).lean() as any;
      const sender = await User.findById(senderId).select("name").lean() as any;
      const fcmToken = receiver?.fcmToken as string | undefined;
      if (fcmToken) {
        await sendPush(
          fcmToken,
          `💬 ${sender?.name ?? "Ai đó"}`,
          content.trim(),
          { type: "message", conversationId: String(conversationId) }
        );
      }
    }

    res.status(201).json(message);
  } catch (error) {
    res.status(500).json({ message: "Send message failed", error });
  }
};

// ── PATCH /conversations/:conversationId/read ─────────────────────────────────
export const markConversationRead = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.userId;
    const { conversationId } = req.params;

    const conversation = await Conversation.findById(conversationId).lean() as ConversationLean | null;
    if (!conversation) {
      return res.status(404).json({ message: "Conversation không tồn tại" });
    }
    if (!isParticipant(conversation.participants, userId)) {
      return res.status(403).json({ message: "Không có quyền" });
    }

    await Conversation.findByIdAndUpdate(conversationId, {
      [`unreadCount.${userId}`]: 0,
    });

    await Message.updateMany(
      { conversationId, senderId: { $ne: userId }, isRead: false },
      { isRead: true }
    );

    res.json({ message: "Đã đánh dấu đọc" });
  } catch (error) {
    res.status(500).json({ message: "Mark read failed", error });
  }
};

// ── DELETE /conversations/:conversationId/messages/:messageId ─────────────────
export const deleteMessage = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.userId;
    const { conversationId, messageId } = req.params;

    const message = await Message.findOne({ _id: messageId, isDeleted: false });
    if (!message) {
      return res.status(404).json({ message: "Tin nhắn không tồn tại" });
    }
    if (message.senderId !== userId) {
      return res.status(403).json({ message: "Chỉ người gửi mới được xóa" });
    }
    if (message.conversationId !== conversationId) {
      return res.status(400).json({ message: "Tin nhắn không thuộc conversation này" });
    }

    message.isDeleted = true;
    await message.save();

    io.to(conversationId).emit("message_deleted", { messageId });

    res.json({ message: "Đã xóa tin nhắn" });
  } catch (error) {
    res.status(500).json({ message: "Delete message failed", error });
  }
};
