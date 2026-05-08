import mongoose from "mongoose";

const RideSchema = new mongoose.Schema(
  {
    userId: {
      type: String,
      required: true,
    },

    userName: {
      type: String,
      default: "",
    },

    type: {
      type: String,
      enum: ["find", "offer"], // tìm xe | chở
      required: true,
    },

    from: {
      id: {
        type: String,
        required: true,
      },

      name: {
        type: String,
        required: true,
      },
    },

    to: {
      id: {
        type: String,
        required: true,
      },

      name: {
        type: String,
        required: true,
      },
    },

    departureTime: {
      type: Date,
      required: true,
    },

    participants: {
      type: [
        {
          userId: String,
          userName: String,

          joinedAt: {
            type: Date,
            default: Date.now,
          },
        },
      ],
      default: [],
    },

    description: {
      type: String,
      default: "",
    },

    contact: {
      type: String,
      default: "",
    },

    status: {
      type: String,
      enum: ["active", "full", "done", "cancelled"],
      default: "active",
    },

    isDeleted: {
      type: Boolean,
      default: false,
    },

    deletedAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

const RideRequestSchema = new mongoose.Schema(
  {
    rideId: {
      type: String,
      required: true,
    },

    userId: {
      type: String,
      required: true,
    },

    userName: {
      type: String,
      default: "",
    },

    message: {
      type: String,
      default: "",
    },

    status: {
      type: String,
      enum: ["pending", "accepted", "rejected"],
      default: "pending",
    },
  },
  {
    timestamps: true,
  }
);

RideRequestSchema.index({ rideId: 1, userId: 1 });



RideSchema.index({ departureTime: 1 });
RideSchema.index({ "from.id": 1, "to.id": 1 });

export const Ride = mongoose.model("Ride", RideSchema);
export const RideRequest = mongoose.model(
  "RideRequest",
  RideRequestSchema
);
