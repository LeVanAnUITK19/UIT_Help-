import jwt from "jsonwebtoken";
import dotenv from "dotenv";

dotenv.config();

const ACCESS_SECRET = process.env.ACCESS_TOKEN_SECRET!;
const REFRESH_SECRET = process.env.REFRESH_TOKEN_SECRET!;
const RESET_SECRET = process.env.RESET_PASSWORD_SECRET!;

export const signAccessToken = (userId: string) => {
  return jwt.sign({ userId }, ACCESS_SECRET, { expiresIn: "30m" });
};

export const signRefreshToken = (userId: string) => {
  return jwt.sign({ userId }, REFRESH_SECRET, { expiresIn: "7d" });
};

export const verifyAccessToken = (token: string) => {
  return jwt.verify(token, ACCESS_SECRET);
};

export const verifyRefreshToken = (token: string) => {
  return jwt.verify(token, REFRESH_SECRET);
};


export const signResetToken = (userId: string) => {
  return jwt.sign({ userId }, RESET_SECRET, { expiresIn: "5m" });
};

export const verifyResetToken = (token: string) => {
  return jwt.verify(token, RESET_SECRET);
};
