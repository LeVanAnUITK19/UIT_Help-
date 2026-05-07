import mongoose from "mongoose";

const userSchema = new mongoose.Schema(
    {
        name: {type: String, required: true},
        mssv: {type: String, required: true, unique: true},
        email: {type: String, required: true, unique: true},
        password: {type: String, required: true},
        refreshToken: {type: String},
        fcmToken: { type: String, default: null },
        otp: {type: String || null},
        otpExpire: {type: Date},
        isVerified: {type: Boolean, default: false},
    },
    {
        timestamps: true
    }
)
userSchema.set("toJSON", {
    transform: (doc, ret) => {
        const r = ret as any; // 👈 tránh lỗi TS

        const formatVN = (date: Date) =>
            new Date(date).toLocaleString("vi-VN", {
                timeZone: "Asia/Ho_Chi_Minh",
            });

        if (r.createdAt) r.createdAtVN = formatVN(r.createdAt);
        if (r.updatedAt) r.updatedAtVN = formatVN(r.updatedAt);

        return r;
    },
});

export default mongoose.model("User", userSchema);