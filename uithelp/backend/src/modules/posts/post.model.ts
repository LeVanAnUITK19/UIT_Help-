import mongoose from "mongoose";

const PostSchema = new mongoose.Schema(
    {
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true
        },
        userName: { type: String, default: "" },
        type: {
            type: String,
            required: true,
            enum: ['found', 'lost'],
            default: 'lost'
        },
        title: { type: String, required: true },
        description: { type: String },
        location: String,
        contact: String,
        imageUrl: String,
        status: {
            type: String,
            required: true,
            enum: ['unclaimed', 'claimed', "searching", "found", "closed"],
            default: 'searching'
        },
        relatedUserId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User"
        },
        commentCount: { type: Number, default: 0 },
        //  AI TAGS
        imageTags: {
            type: [String],
            default: [],
        },
        isDeleted: { type: Boolean, default: false },
        deletedAt: { type: Date, default: null },
    },
    {
        timestamps: true
    }
);

PostSchema.set("toJSON", {
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


export default mongoose.model("Post", PostSchema);