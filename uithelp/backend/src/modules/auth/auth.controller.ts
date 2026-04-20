// controllers/auth.controller.ts
import bcrypt from "bcrypt";
import User from "../auth/auth.model";
import { Request, Response } from "express";
import nodemailer from "nodemailer";

import {
    signAccessToken,
    signRefreshToken,
    verifyRefreshToken,
    verifyAccessToken,
    signResetToken,
    verifyResetToken

} from "../../utils/jwt";


// REGISTER
export const register = async (req: Request, res: Response) => {
    let { name, mssv, password, confirmPassword } = req.body;

    if (name == null || mssv == null || password == null || confirmPassword == null) {
        return res.status(400).json({ message: "Điền đầy đủ thông tin" });
    }

    let email = mssv + "@gm.uit.edu.vn";
    const userExist = await User.findOne({ mssv });
    if (userExist) {
        return res.status(400).json({ message: "MSSV đã được đăng ký" });
    }
    if (password != confirmPassword) {
        return res.status(400).json({ message: "Mật khẩu không khớp" });
    }
    const otp = (Math.floor(100000 + Math.random() * 900000) as any).toString();

    const hashed = await bcrypt.hash(password, 10);

    const user = await User.create({
        name,
        mssv,
        email,
        password: hashed,
        otp,
        otpExpire: Date.now() + 5 * 60 * 1000,
        isVerified: false,
    });

    // gửi OTP (email service)
    await sendEmail(email, otp);
    res.json({ message: "OTP đã gửi, Chờ xác thực" });
};

// LOGIN
export const login = async (req: Request, res: Response) => {
    let { mssv, password } = req.body;

    if (!mssv || !password) return res.status(400).json({ message: "Điền đầy đủ thông tin" });

    const user = await User.findOne({ mssv });
    if (!user) return res.status(400).json({ message: "Không tìm thấy tài khoản" });
    if (!user.isVerified) return res.status(400).json({ message: "Tài khoản chưa xác thực" });

    const match = await bcrypt.compare(password, user.password);
    if (!match) return res.status(400).json({ message: "Mật khẩu sai" });

    const accessToken = signAccessToken(user._id.toString());
    const refreshToken = signRefreshToken(user._id.toString());

    // lưu refresh token vào DB
    user.refreshToken = refreshToken;
    await user.save();

    // gửi refresh token qua cookie
    res.cookie("refreshToken", refreshToken, {
        httpOnly: true,
        secure: false, // production => true
        sameSite: "strict",
    });

    res.json({
        accessToken,
        user: {
            id: user._id,
            name: user.name,
            mssv: user.mssv,
            email: user.email,
        }
    });
};

//Refresh Token
export const refresh = async (req: Request, res: Response) => {
    const token = req.cookies.refreshToken;
    if (!token) return res.sendStatus(401);

    try {
        const decoded: any = verifyRefreshToken(token);

        const user = await User.findById(decoded.userId);
        if (!user || user.refreshToken !== token) {
            return res.sendStatus(403);
        }

        // ROTATE REFRESH TOKEN
        const newRefreshToken = signRefreshToken(user._id.toString());
        const newAccessToken = signAccessToken(user._id.toString());

        user.refreshToken = newRefreshToken;
        await user.save();

        res.cookie("refreshToken", newRefreshToken, {
            httpOnly: true,
            secure: false,
            sameSite: "strict",
        });

        res.json({ accessToken: newAccessToken });
    } catch (err) {
        return res.sendStatus(403);
    }
};

//Logout
export const logout = async (req: Request, res: Response) => {
    const token = req.cookies.refreshToken;
    if (!token) return res.sendStatus(204);

    try {
        const decoded: any = verifyRefreshToken(token);

        const user = await User.findById(decoded.userId);
        if (user) {
            user.refreshToken = "";
            await user.save();
        }
    } catch (err) {
        // ignore invalid token
    }

    res.clearCookie("refreshToken");
    res.json({ message: "Logged out" });
};
//ForgetPassword
export const forgotPassword = async (req: Request, res: Response) => {
    let { mssv } = req.body;


    let email = mssv + "@gm.uit.edu.vn";


    const user = await User.findOne({ email });
    if (!user) return res.status(400).json({ message: "Không tồn tại user" });
    if (!user.isVerified) return res.status(400).json({ message: "Tài khoản chưa xác thực" });


    const otp = Math.floor(100000 + Math.random() * 900000).toString();

    user.otp = otp;
    user.otpExpire = new Date(Date.now() + 5 * 60 * 1000);
    await user.save();

    await sendEmail(email, otp);

    res.json({ message: "OTP đã gửi" });
};
//verifyForgotOtp
export const verifyForgotOtp = async (req: Request, res: Response) => {
    const { email, otp } = req.body;

    const user = await User.findOne({ email });

    if (!user || user.otp !== otp) {
        return res.status(400).json({ message: "OTP sai" });
    }

    if (!user.otpExpire || user.otpExpire < new Date()) {
        return res.status(400).json({ message: "OTP hết hạn" });
    }

    // tạo reset token ngắn hạn
    const resetToken = signResetToken(user._id.toString());

    res.json({ resetToken });
};
//verifyRegisterOtp
export const verifyRegisterOtp = async (req: Request, res: Response) => {
    const { email, otp } = req.body;

    const user = await User.findOne({ email });

    if (!user || user.otp !== otp) {
        return res.status(400).json({ message: "OTP sai" });
    }

    if (!user.otpExpire || user.otpExpire < new Date()) {
        return res.status(400).json({ message: "OTP hết hạn" });
    }
    user.isVerified = true;
    user.otp = null;
    user.otpExpire = null;
    await user.save();
    res.json({message: "Xác thực thành công"});
};
//resetPassword
export const resetPassword = async (req: Request, res: Response) => {
    const { resetToken, newPassword } = req.body;

    interface JwtPayloadCustom {
        userId: string;
    }

    const decoded = verifyResetToken(resetToken) as { userId: string };
    const user = await User.findById(decoded.userId);

    if (!user) return res.status(400).json({ message: "User không tồn tại" });

    user.password = await bcrypt.hash(newPassword, 10);
    user.otp = null;
    user.otpExpire = null;

    await user.save();

    res.json({ message: "Đổi mật khẩu thành công" });
};
//sendEmail
export const sendEmail = async (to: string, otp: string) => {
    const transporter = nodemailer.createTransport({
        service: "gmail",
        auth: {
            user: process.env.EMAIL_USER,
            pass: process.env.EMAIL_PASS,
        },
    });

    await transporter.sendMail({
        to,
        subject: "OTP UIT_Help",
        text: `Mã OTP của bạn là: ${otp}`,
    });
};