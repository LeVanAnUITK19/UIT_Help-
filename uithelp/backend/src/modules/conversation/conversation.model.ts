import mongoose from "mongoose";

const ConversationSchema = new mongoose.Schema(
  {
    participants: [{ type: String, required: true }], // [userA, userB]

    lastMessage: { type: String, default: "" },

    lastMessageAt: { type: Date },

   
    unreadCount: {
      type: Map,
      of: Number, // { userId: number }
      default: {},
    },
  },
  { timestamps: true }
);

ConversationSchema.index({ participants: 1 });

export default mongoose.model("Conversation", ConversationSchema);