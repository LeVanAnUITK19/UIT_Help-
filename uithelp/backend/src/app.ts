import express from "express";
import cors from "cors";
import cookieParser from "cookie-parser";
import authRoutes from "./modules/auth/auth.route";
import postRoutes from "./modules/posts/post.route";
import commentRoutes from "./modules/comments/comment.route";
import locketRoutes from "./modules/locket/locket.route";
import notificationRoutes from "./modules/notifications/notification.route";
import conversationRoutes from "./modules/conversation/conversation.route";

const app = express();

app.use(cors({
  origin: (origin, callback) => callback(null, true),
  credentials: true,
  methods: ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization"],
}));
app.options("/{*path}", cors());
app.use(express.json());
app.use(cookieParser());

app.use("/api/auth", authRoutes);
app.use("/api/posts", postRoutes);
app.use("/api/comments", commentRoutes);
app.use("/api/lockets", locketRoutes);
app.use("/api/notifications", notificationRoutes);
app.use("/api/conversations", conversationRoutes);

export default app;