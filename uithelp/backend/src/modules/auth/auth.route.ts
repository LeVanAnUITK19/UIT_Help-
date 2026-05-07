import express from "express";
import {
  register,
  login,
  refresh,
  logout,
  forgotPassword,
  verifyForgotOtp,
  resetPassword,
  verifyRegisterOtp,
  updateFcmToken,
  getFcmToken,
} from "../auth/auth.controller";
import { authMiddleware } from "../../middleware/auth.middleware";
import { Request, Response } from "express";

const router = express.Router();

router.post("/register", register);
router.post("/login", login);
router.post("/refresh", refresh);
router.post("/logout", logout);
router.post("/forgetPassword", forgotPassword);
router.post("/verifyForgotOtp", verifyForgotOtp);
router.post("/verifyRegisterOtp", verifyRegisterOtp);
router.post("/resetPassword", resetPassword);
router.put("/fcm-token", authMiddleware, updateFcmToken);
router.get("/fcm-token", authMiddleware, getFcmToken);

router.get("/profile", authMiddleware, async (req: Request, res: Response) => {
  const user = await (await import("../auth/auth.model")).default
    .findById(req.user.userId)
    .select("name mssv email createdAt");
  if (!user) return res.status(404).json({ message: "User not found" });
  res.json({
    id: user._id,
    name: user.name,
    mssv: user.mssv,
    email: user.email,
    createdAt: user.createdAt,
  });
});

router.get("/users/:id", authMiddleware, async (req: Request, res: Response) => {
  const user = await (await import("../auth/auth.model")).default
    .findById(req.params.id)
    .select("name mssv email createdAt");
  if (!user) return res.status(404).json({ message: "User not found" });
  res.json({
    id: user._id,
    name: user.name,
    mssv: user.mssv,
    email: user.email,
    createdAt: user.createdAt,
  });
});

export default router;