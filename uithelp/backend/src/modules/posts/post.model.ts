import mongoose from "mongoose";

const PostSchema = new mongoose.Schema(
    {
        userId: { type: String, required: true},
        type: {type: String,
            required: true,
            enum: ['found', 'lost'],
            default: 'lost'
        },
        title: {type: String, required: true},
        description: {type: String},
        location: String,
        contact: String,
        imageUrl: String,
        status: {
            type: String,
            required: true,
            enum: ['unclaimed', 'claimed', "searching", "found", "closed"],
            default: 'searching'
        },
        relatedUserId: {type: String}

    },
    {
        timestamps: true
    }
);
    

export default mongoose.model("Post", PostSchema);