import { Router } from "express";
import { authMiddleware } from "../../middleware/auth.middleware";
import {
  getConversations,
  getOrCreateConversation,
  getMessages,
  sendMessage,
  markConversationRead,
  deleteMessage,
} from "./conversation.controller";

const router = Router();

router.use(authMiddleware);

// Conversation list + create
router.get("/", getConversations);
router.post("/", getOrCreateConversation);

// Messages
router.get("/:conversationId/messages", getMessages);
router.post("/:conversationId/messages", sendMessage);

// Mark read
router.patch("/:conversationId/read", markConversationRead);

// Delete message
router.delete("/:conversationId/messages/:messageId", deleteMessage);

export default router;
