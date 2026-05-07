// server.ts
import dotenv from "dotenv";
import http from "http";
import { Server } from "socket.io";
import { connectDB } from "./config/db";
import app from "./app";
import { registerCommentSocket } from "./sockets/comment.socket";

dotenv.config();

const httpServer = http.createServer(app);

export const io = new Server(httpServer, {
  cors: { origin: "*" },
});

registerCommentSocket(io); // đăng ký socket events

const startServer = async () => {
  await connectDB();
  console.log("DB connected");

  const PORT = Number(process.env.PORT) || 5001;
  httpServer.listen(PORT, "0.0.0.0", () => {
    console.log(`Server running on port ${PORT}`);
  });
};

startServer();
