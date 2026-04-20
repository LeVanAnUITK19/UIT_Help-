import mongoose from "mongoose";

const userSchema = new mongoose.Schema(
    {
        name: {type: String, required: true},
        mssv: {type: String, required: true, unique: true},
        email: {type: String, required: true, unique: true},
        password: {type: String, required: true},
        refreshToken: {type: String},
        otp: {type: String || null},
        otpExpire: {type: Date},
        isVerified: {type: Boolean, default: false},
    },
    {
        timestamps: true
    }
)

export default mongoose.model("User", userSchema);