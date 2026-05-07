import mongoose from "mongoose";

const CommentSchema = new mongoose.Schema(
    {
        postId: { type: String, required: true },
        userId: { type: String, required: true },
        userName: { type: String, default: "" },
        content: { type: String, required: true },
        isDeleted: { type: Boolean, default: false },
        deletedAt: { type: Date, default: null },
    },
    {
        timestamps: true
    }
);

CommentSchema.set("toJSON", {
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

export default mongoose.model("Comment", CommentSchema);