import mongoose from "mongoose";

const NotificationSchema = new mongoose.Schema(
  {
    userId: { type: String, required: true }, // người nhận

    type: {
      type: String,
      enum: [
        "match",
        "comment",
        "reaction",
        "ride_join",
      ],
      required: true,
    },

    title: { type: String, required: true },
    message: { type: String },

    // 🔥 liên kết dữ liệu
    postId: { type: String },
    locketId: { type: String },
    rideId: { type: String },

    senderId: { type: String }, // ai gây ra

    isRead: { type: Boolean, default: false },

    isDeleted: { type: Boolean, default: false },
    deletedAt: { type: Date, default: null },
  },
  {
    timestamps: true,
  }
);

NotificationSchema.index({ userId: 1, createdAt: -1 });
NotificationSchema.index({ userId: 1, isRead: 1 });

export default mongoose.model("Notification", NotificationSchema);