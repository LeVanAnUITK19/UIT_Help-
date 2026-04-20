import dotenv from "dotenv";
import { connectDB } from "./config/db";
import app from "./app";

dotenv.config();

const startServer = async () => {
  await connectDB();
  console.log("DB connected");

  const PORT = Number(process.env.PORT) || 5001;

  app.listen(PORT, "0.0.0.0", () => {
    console.log(`Server running on port ${PORT}`);
  });
};

startServer();