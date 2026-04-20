import { verifyAccessToken } from "../utils/jwt";
import { Request, Response, NextFunction } from "express";

declare module "express" {
  export interface Request {
    user?: any;
  }
}

export const authMiddleware = (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  const header = req.headers.authorization;

  if (!header?.startsWith("Bearer ")) {
    return res.sendStatus(401);
  }

  const token = header.split(" ")[1];

  try {
    const decoded = verifyAccessToken(token) as { userId: string };
    req.user = decoded;
    next();
  } catch {
    return res.sendStatus(403);
  }
};