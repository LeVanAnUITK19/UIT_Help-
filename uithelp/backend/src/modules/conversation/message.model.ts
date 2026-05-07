import mongoose from "mongoose";

const MessageSchema = new mongoose.Schema(
  {
    conversationId: { type: String, required: true },

    senderId: { type: String, required: true },

    content: { type: String },

    type: {
      type: String,
      enum: ["text", "image"],
      default: "text",
    },

    isRead: { type: Boolean, default: false },

    isDeleted: { type: Boolean, default: false },
  },
  { timestamps: true }
);

MessageSchema.index({ conversationId: 1, createdAt: -1 });

export default mongoose.model("Message", MessageSchema);