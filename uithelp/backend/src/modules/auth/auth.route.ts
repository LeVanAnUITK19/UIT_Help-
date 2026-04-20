import express from "express";
import {
  register,
  login,
  refresh,
  logout,
  forgotPassword,
  verifyForgotOtp,
  resetPassword,
  verifyRegisterOtp
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

router.get("/profile", authMiddleware, (req: Request, res: Response) => {
  res.json({ user: req.user });
});

export default router;