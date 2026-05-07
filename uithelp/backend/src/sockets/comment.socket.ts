// sockets/comment.socket.ts
import { Server } from "socket.io";

export const registerCommentSocket = (io: Server) => {
  io.on("connection", (socket) => {
    // ── Post comment rooms ──────────────────────────────────────────────────
    socket.on("join_post", (postId: string) => {
      socket.join(postId);
    });
    socket.on("leave_post", (postId: string) => {
      socket.leave(postId);
    });

    // ── Conversation (chat) rooms ───────────────────────────────────────────
    socket.on("join_conversation", (conversationId: string) => {
      socket.join(conversationId);
    });
    socket.on("leave_conversation", (conversationId: string) => {
      socket.leave(conversationId);
    });

    // Typing indicator
    socket.on("typing", ({ conversationId, userId }: { conversationId: string; userId: string }) => {
      socket.to(conversationId).emit("user_typing", { userId });
    });
    socket.on("stop_typing", ({ conversationId, userId }: { conversationId: string; userId: string }) => {
      socket.to(conversationId).emit("user_stop_typing", { userId });
    });
  });
};
