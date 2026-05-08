import mongoose from "mongoose";

const MatchSchema = new mongoose.Schema(
    {
        postA: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "Post",
            required: true,
        },
        postB: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "Post",
            required: true,
        },
        score: {
            type: Number,
            required: true,
        },
        //lưu lý do match
        matchedFields: {
            location: Boolean,
            text: Boolean,
            image: Boolean,
            time: Boolean,
        },
        // quản lý notify
        isNotified: {
            type: Boolean,
            default: false,
        },
        notifiedAt: Date,
        createdAt: Date,
    },
    { timestamps: true }
)

export default mongoose.model("Match", MatchSchema);