import mongoose from "mongoose";

const LocketSchema = new mongoose.Schema(
    {
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true
        },
        userName: { type: String, default: "" },
        imageUrl: { type: String, required: true },
        caption: { type: String, default: null },
        reactionsCount: { type: Number, default: 0 },

        expiresAt: { type: Date, default: () => Date.now() + 7 * 24 * 60 * 60 * 1000 },
        isDeleted: { type: Boolean, default: false },
        deletedAt: { type: Date, default: null },
    },
    {
        timestamps: true
    }
);
const LocketReactionSchema = new mongoose.Schema(
    {
        locketId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "Locket",
            required: true
        },
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true
        },
        userName: { type: String, default: "" },
        type: {
            type: String,
            required: true,
            enum: ['like', 'heart', 'smile', 'sad'],
            default: 'like'
        },
        isDeleted: { type: Boolean, default: false },
        deletedAt: { type: Date, default: null },
    },
    {
        timestamps: true
    }
)

const LocketCommentSchema = new mongoose.Schema(
    {
        locketId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "Locket",
            required: true
        },
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true
        },
        userName: { type: String, default: "" },
        content: { type: String, required: true },
        commentsCount: { type: Number, default: 0 },
    },
    {
        timestamps: true
    }
)

LocketSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });
LocketReactionSchema.index(
    { locketId: 1, userId: 1 },
    { unique: true }
);

export const Locket = mongoose.model("Locket", LocketSchema);
export const LocketReaction = mongoose.model("LocketReaction", LocketReactionSchema);
export const LocketComment = mongoose.model("LocketComment", LocketCommentSchema);