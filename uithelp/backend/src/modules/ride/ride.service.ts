import { Ride, RideRequest } from "./ride.model";
import User from "../auth/auth.model";
import { createNotification } from "../notifications/notification.service";

// ─── RIDE CRUD ────────────────────────────────────────────────────────────────

export const createRideService = async (
  userId: string,
  body: {
    type: "find" | "offer";
    from: { id: string; name: string };
    to: { id: string; name: string };
    departureTime: Date;
    description?: string;
    contact?: string;
  }
) => {
  const user = await User.findById(userId);
  const ride = await Ride.create({
    userId,
    userName: user?.name ?? "",
    ...body,
    status: "active",
  });
  return ride;
};

export const getRidesService = async (query: {
  cursor?: string;
  type?: string;
  fromId?: string;
  toId?: string;
  status?: string;
}) => {
  const limit = 10;
  const filter: any = { isDeleted: false };

  if (query.cursor) filter._id = { $lt: query.cursor };
  if (query.type) filter.type = query.type;
  if (query.fromId) filter["from.id"] = query.fromId;
  if (query.toId) filter["to.id"] = query.toId;
  if (query.status) filter.status = query.status;
  else filter.status = { $in: ["active", "full"] }; // mặc định ẩn done/cancelled

  const rides = await Ride.find(filter).sort({ _id: -1 }).limit(limit);
  const nextCursor = rides.length === limit ? rides[rides.length - 1]._id : null;
  return { rides, nextCursor };
};

export const getRideByIdService = async (rideId: string) => {
  return Ride.findOne({ _id: rideId, isDeleted: false });
};

export const updateRideService = async (
  rideId: string,
  userId: string,
  body: Partial<{
    from: { id: string; name: string };
    to: { id: string; name: string };
    departureTime: Date;
    description: string;
    contact: string;
  }>
) => {
  const ride = await Ride.findOne({ _id: rideId, isDeleted: false });
  if (!ride) return { error: "not_found" };
  if (ride.userId !== userId) return { error: "forbidden" };
  if (ride.status === "done" || ride.status === "cancelled")
    return { error: "ride_ended" };

  Object.assign(ride, body);
  await ride.save();
  return { ride };
};

export const deleteRideService = async (rideId: string, userId: string) => {
  const ride = await Ride.findOne({ _id: rideId, isDeleted: false });
  if (!ride) return { error: "not_found" };
  if (ride.userId !== userId) return { error: "forbidden" };

  ride.isDeleted = true;
  ride.deletedAt = new Date();
  await ride.save();
  return { success: true };
};

// ─── JOIN / REQUEST ───────────────────────────────────────────────────────────

export const requestJoinRideService = async (
  rideId: string,
  userId: string,
  message?: string
) => {
  const ride = await Ride.findOne({ _id: rideId, isDeleted: false });
  if (!ride) return { error: "not_found" };
  if (ride.status === "full") return { error: "ride_full" };
  if (ride.status === "done" || ride.status === "cancelled")
    return { error: "ride_ended" };
  if (ride.userId === userId) return { error: "own_ride" };

  // Kiểm tra đã là participant chưa
  const alreadyJoined = ride.participants.some((p: any) => p.userId === userId);
  if (alreadyJoined) return { error: "already_joined" };

  // Kiểm tra đã gửi request chưa
  const existing = await RideRequest.findOne({ rideId, userId, status: "pending" });
  if (existing) return { error: "already_requested" };

  const user = await User.findById(userId);
  const rideRequest = await RideRequest.create({
    rideId,
    userId,
    userName: user?.name ?? "",
    message: message ?? "",
    status: "pending",
  });

  // 🔔 Thông báo cho chủ xe: có người muốn đi cùng
  await createNotification({
    userId: ride.userId,
    type: "ride_request",
    title: `${user?.name ?? "Ai đó"} muốn đi học cùng bạn`,
    message: message || `Tuyến: ${ride.from?.name} → ${ride.to?.name}`,
    senderId: userId,
    rideId: ride._id.toString(),
  });

  return { rideRequest };
};

export const getRideRequestsService = async (rideId: string, ownerId: string) => {
  const ride = await Ride.findOne({ _id: rideId, isDeleted: false });
  if (!ride) return { error: "not_found" };
  if (ride.userId !== ownerId) return { error: "forbidden" };

  const requests = await RideRequest.find({ rideId, status: "pending" }).sort({ createdAt: -1 });
  return { requests };
};

export const acceptRideRequestService = async (
  requestId: string,
  ownerId: string
) => {
  const rideRequest = await RideRequest.findById(requestId);
  if (!rideRequest) return { error: "not_found" };
  if (rideRequest.status !== "pending") return { error: "already_handled" };

  const ride = await Ride.findOne({ _id: rideRequest.rideId, isDeleted: false });
  if (!ride) return { error: "ride_not_found" };
  if (ride.userId !== ownerId) return { error: "forbidden" };

  // 🚗 offer: participants.length >= 1 → full
  // ⚡ find: offerParticipants.length >= 1 → full (tương tự logic)
  if (ride.participants.length >= 1) {
    // Đã đủ chỗ, reject request này
    rideRequest.status = "rejected";
    await rideRequest.save();
    return { error: "ride_full" };
  }

  // Thêm vào participants
  ride.participants.push({
    userId: rideRequest.userId,
    userName: rideRequest.userName,
    joinedAt: new Date(),
  });

  // Sau khi accept → đủ 1 người → full
  ride.status = "full";

  rideRequest.status = "accepted";

  // Reject tất cả pending requests còn lại
  await RideRequest.updateMany(
    { rideId: ride._id.toString(), status: "pending", _id: { $ne: requestId } },
    { status: "rejected" }
  );

  await ride.save();
  await rideRequest.save();

  // 🔔 Thông báo cho người gửi request: được chấp nhận
  await createNotification({
    userId: rideRequest.userId,
    type: "ride_accepted",
    title: "Yêu cầu đi học cùng được chấp nhận! 🎉",
    message: `Tuyến: ${ride.from?.name} → ${ride.to?.name}`,
    senderId: ride.userId,
    rideId: ride._id.toString(),
  });

  return { ride, rideRequest };
};

export const rejectRideRequestService = async (
  requestId: string,
  ownerId: string
) => {
  const rideRequest = await RideRequest.findById(requestId);
  if (!rideRequest) return { error: "not_found" };
  if (rideRequest.status !== "pending") return { error: "already_handled" };

  const ride = await Ride.findOne({ _id: rideRequest.rideId, isDeleted: false });
  if (!ride) return { error: "ride_not_found" };
  if (ride.userId !== ownerId) return { error: "forbidden" };

  rideRequest.status = "rejected";
  await rideRequest.save();

  // 🔔 Thông báo cho người gửi request: bị từ chối
  await createNotification({
    userId: rideRequest.userId,
    type: "ride_rejected",
    title: "Yêu cầu đi học cùng chưa được chấp nhận",
    message: `Tuyến: ${ride.from?.name} → ${ride.to?.name}`,
    senderId: ride.userId,
    rideId: ride._id.toString(),
  });

  return { rideRequest };
};

// ─── MATCHING ─────────────────────────────────────────────────────────────────

export const getMatchedRidesService = async (rideId: string, userId: string) => {
  const ride = await Ride.findOne({ _id: rideId, isDeleted: false });
  if (!ride) return { error: "not_found" };

  // Tìm các ride ngược type, cùng from/to, cùng ngày, còn active
  const oppositeType = ride.type === "find" ? "offer" : "find";

  const departureDate = new Date(ride.departureTime);
  const startOfDay = new Date(departureDate);
  startOfDay.setHours(0, 0, 0, 0);
  const endOfDay = new Date(departureDate);
  endOfDay.setHours(23, 59, 59, 999);

  const matches = await Ride.find({
    isDeleted: false,
    type: oppositeType,
    "from.id": ride.from?.id,
    "to.id": ride.to?.id,
    departureTime: { $gte: startOfDay, $lte: endOfDay },
    status: { $in: ["active", "full"] },
    _id: { $ne: rideId },
  }).sort({ departureTime: 1 });

  return { matches };
};

// ─── USER ─────────────────────────────────────────────────────────────────────

export const getMyRidesService = async (userId: string, cursor?: string) => {
  const limit = 10;
  const filter: any = { userId, isDeleted: false };
  if (cursor) filter._id = { $lt: cursor };

  const rides = await Ride.find(filter).sort({ _id: -1 }).limit(limit);
  const nextCursor = rides.length === limit ? rides[rides.length - 1]._id : null;
  return { rides, nextCursor };
};

export const getJoinedRidesService = async (userId: string, cursor?: string) => {
  const limit = 10;
  const filter: any = {
    isDeleted: false,
    "participants.userId": userId,
  };
  if (cursor) filter._id = { $lt: cursor };

  const rides = await Ride.find(filter).sort({ _id: -1 }).limit(limit);
  const nextCursor = rides.length === limit ? rides[rides.length - 1]._id : null;
  return { rides, nextCursor };
};

export const getMyRideRequestsService = async (userId: string) => {
  const requests = await RideRequest.find({ userId }).sort({ createdAt: -1 });
  return { requests };
};

export const cancelRideRequestService = async (requestId: string, userId: string) => {
  const rideRequest = await RideRequest.findOne({ _id: requestId, userId });
  if (!rideRequest) return { error: "not_found" };
  if (rideRequest.status !== "pending") return { error: "cannot_cancel" };

  rideRequest.status = "rejected";
  await rideRequest.save();
  return { success: true };
};

export const leaveRideService = async (rideId: string, userId: string) => {
  const ride = await Ride.findOne({ _id: rideId, isDeleted: false });
  if (!ride) return { error: "not_found" };

  const idx = ride.participants.findIndex((p: any) => p.userId === userId);
  if (idx === -1) return { error: "not_participant" };
  if (ride.status === "done" || ride.status === "cancelled")
    return { error: "ride_ended" };

  ride.participants.splice(idx, 1);
  // Sau khi rời → còn < 1 người → active lại
  if (ride.participants.length < 1) ride.status = "active";

  await ride.save();
  return { success: true };
};

export const removeParticipantService = async (
  rideId: string,
  ownerId: string,
  targetUserId: string
) => {
  const ride = await Ride.findOne({ _id: rideId, isDeleted: false });
  if (!ride) return { error: "not_found" };
  if (ride.userId !== ownerId) return { error: "forbidden" };
  if (ride.status === "done" || ride.status === "cancelled")
    return { error: "ride_ended" };

  const idx = ride.participants.findIndex((p: any) => p.userId === targetUserId);
  if (idx === -1) return { error: "not_participant" };

  ride.participants.splice(idx, 1);
  if (ride.participants.length < 1) ride.status = "active";

  await ride.save();
  return { ride };
};

// ─── STATUS ───────────────────────────────────────────────────────────────────

export const completeRideService = async (rideId: string, userId: string) => {
  const ride = await Ride.findOne({ _id: rideId, isDeleted: false });
  if (!ride) return { error: "not_found" };
  if (ride.userId !== userId) return { error: "forbidden" };
  if (ride.status === "cancelled") return { error: "already_cancelled" };
  if (ride.status === "done") return { error: "already_done" };

  ride.status = "done";
  await ride.save();
  return { ride };
};

export const cancelRideService = async (rideId: string, userId: string) => {
  const ride = await Ride.findOne({ _id: rideId, isDeleted: false });
  if (!ride) return { error: "not_found" };
  if (ride.userId !== userId) return { error: "forbidden" };
  if (ride.status === "done") return { error: "already_done" };
  if (ride.status === "cancelled") return { error: "already_cancelled" };

  ride.status = "cancelled";
  // Reject tất cả pending requests
  await RideRequest.updateMany({ rideId: ride._id.toString(), status: "pending" }, { status: "rejected" });
  await ride.save();
  return { ride };
};
