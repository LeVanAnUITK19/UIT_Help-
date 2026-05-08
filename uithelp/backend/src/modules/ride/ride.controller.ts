import { Request, Response } from "express";
import {
  createRideService,
  getRidesService,
  getRideByIdService,
  updateRideService,
  deleteRideService,
  requestJoinRideService,
  getRideRequestsService,
  acceptRideRequestService,
  rejectRideRequestService,
  getMatchedRidesService,
  getMyRidesService,
  getJoinedRidesService,
  getMyRideRequestsService,
  cancelRideRequestService,
  leaveRideService,
  removeParticipantService,
  completeRideService,
  cancelRideService,
} from "./ride.service";

// helper: ép kiểu param về string
const p = (v: string | string[]): string => (Array.isArray(v) ? v[0] : v);

// ─── RIDE CRUD ────────────────────────────────────────────────────────────────

export const createRide = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.userId;
    const { type, from, to, departureTime, description, contact } = req.body;

    if (!type || !from || !to || !departureTime) {
      return res.status(400).json({ message: "Thiếu thông tin bắt buộc" });
    }

    const ride = await createRideService(userId, {
      type,
      from,
      to,
      departureTime,
      description,
      contact,
    });

    res.status(201).json(ride);
  } catch (error) {
    res.status(500).json({ message: "Tạo chuyến đi thất bại", error });
  }
};

export const getRides = async (req: Request, res: Response) => {
  try {
    const { cursor, type, fromId, toId, status } = req.query as Record<string, string>;
    const result = await getRidesService({ cursor, type, fromId, toId, status });
    res.json(result);
  } catch (error) {
    res.status(500).json({ message: "Lấy danh sách chuyến đi thất bại", error });
  }
};

export const getRideById = async (req: Request, res: Response) => {
  try {
    const id = p(req.params.id);
    const ride = await getRideByIdService(id);
    if (!ride) return res.status(404).json({ message: "Không tìm thấy chuyến đi" });
    res.json(ride);
  } catch (error) {
    res.status(500).json({ message: "Lấy chuyến đi thất bại", error });
  }
};

export const updateRide = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.userId;
    const id = p(req.params.id);
    const result = await updateRideService(id, userId, req.body);

    if (result.error === "not_found") return res.status(404).json({ message: "Không tìm thấy chuyến đi" });
    if (result.error === "forbidden") return res.status(403).json({ message: "Không có quyền" });
    if (result.error === "ride_ended") return res.status(400).json({ message: "Chuyến đi đã kết thúc" });

    res.json(result.ride);
  } catch (error) {
    res.status(500).json({ message: "Cập nhật chuyến đi thất bại", error });
  }
};

export const deleteRide = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.userId;
    const id = p(req.params.id);
    const result = await deleteRideService(id, userId);

    if (result.error === "not_found") return res.status(404).json({ message: "Không tìm thấy chuyến đi" });
    if (result.error === "forbidden") return res.status(403).json({ message: "Không có quyền" });

    res.json({ message: "Xóa thành công" });
  } catch (error) {
    res.status(500).json({ message: "Xóa chuyến đi thất bại", error });
  }
};

// ─── JOIN / REQUEST ───────────────────────────────────────────────────────────

export const requestJoinRide = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.userId;
    const id = p(req.params.id);
    const { message } = req.body;

    const result = await requestJoinRideService(id, userId, message);

    if (result.error === "not_found") return res.status(404).json({ message: "Không tìm thấy chuyến đi" });
    if (result.error === "ride_full") return res.status(400).json({ message: "Chuyến đi đã đầy" });
    if (result.error === "ride_ended") return res.status(400).json({ message: "Chuyến đi đã kết thúc" });
    if (result.error === "own_ride") return res.status(400).json({ message: "Không thể tham gia chuyến đi của chính mình" });
    if (result.error === "already_joined") return res.status(400).json({ message: "Bạn đã tham gia chuyến đi này" });
    if (result.error === "already_requested") return res.status(400).json({ message: "Bạn đã gửi yêu cầu rồi" });

    res.status(201).json(result.rideRequest);
  } catch (error) {
    res.status(500).json({ message: "Gửi yêu cầu tham gia thất bại", error });
  }
};

export const getRideRequests = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.userId;
    const id = p(req.params.id);

    const result = await getRideRequestsService(id, userId);

    if (result.error === "not_found") return res.status(404).json({ message: "Không tìm thấy chuyến đi" });
    if (result.error === "forbidden") return res.status(403).json({ message: "Không có quyền" });

    res.json(result.requests);
  } catch (error) {
    res.status(500).json({ message: "Lấy danh sách yêu cầu thất bại", error });
  }
};

export const acceptRideRequest = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.userId;
    const requestId = p(req.params.requestId);

    const result = await acceptRideRequestService(requestId, userId);

    if (result.error === "not_found") return res.status(404).json({ message: "Không tìm thấy yêu cầu" });
    if (result.error === "already_handled") return res.status(400).json({ message: "Yêu cầu đã được xử lý" });
    if (result.error === "ride_not_found") return res.status(404).json({ message: "Không tìm thấy chuyến đi" });
    if (result.error === "forbidden") return res.status(403).json({ message: "Không có quyền" });
    if (result.error === "ride_full") return res.status(400).json({ message: "Chuyến đi đã đầy, yêu cầu bị từ chối" });

    res.json({ message: "Chấp nhận thành công", ride: result.ride, rideRequest: result.rideRequest });
  } catch (error) {
    res.status(500).json({ message: "Chấp nhận yêu cầu thất bại", error });
  }
};

export const rejectRideRequest = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.userId;
    const requestId = p(req.params.requestId);

    const result = await rejectRideRequestService(requestId, userId);

    if (result.error === "not_found") return res.status(404).json({ message: "Không tìm thấy yêu cầu" });
    if (result.error === "already_handled") return res.status(400).json({ message: "Yêu cầu đã được xử lý" });
    if (result.error === "ride_not_found") return res.status(404).json({ message: "Không tìm thấy chuyến đi" });
    if (result.error === "forbidden") return res.status(403).json({ message: "Không có quyền" });

    res.json({ message: "Từ chối thành công", rideRequest: result.rideRequest });
  } catch (error) {
    res.status(500).json({ message: "Từ chối yêu cầu thất bại", error });
  }
};

// ─── MATCHING ─────────────────────────────────────────────────────────────────

export const getMatchedRides = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.userId;
    const id = p(req.params.id);

    const result = await getMatchedRidesService(id, userId);

    if (result.error === "not_found") return res.status(404).json({ message: "Không tìm thấy chuyến đi" });

    res.json(result.matches);
  } catch (error) {
    res.status(500).json({ message: "Lấy danh sách matching thất bại", error });
  }
};

// ─── USER ─────────────────────────────────────────────────────────────────────

export const getMyRides = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.userId;
    const { cursor } = req.query as { cursor?: string };
    const result = await getMyRidesService(userId, cursor);
    res.json(result);
  } catch (error) {
    res.status(500).json({ message: "Lấy chuyến đi của tôi thất bại", error });
  }
};

export const getJoinedRides = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.userId;
    const { cursor } = req.query as { cursor?: string };
    const result = await getJoinedRidesService(userId, cursor);
    res.json(result);
  } catch (error) {
    res.status(500).json({ message: "Lấy chuyến đi đã tham gia thất bại", error });
  }
};

export const getMyRideRequests = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.userId;
    const result = await getMyRideRequestsService(userId);
    res.json(result.requests);
  } catch (error) {
    res.status(500).json({ message: "Lấy yêu cầu của tôi thất bại", error });
  }
};

export const cancelRideRequest = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.userId;
    const requestId = p(req.params.requestId);

    const result = await cancelRideRequestService(requestId, userId);

    if (result.error === "not_found") return res.status(404).json({ message: "Không tìm thấy yêu cầu" });
    if (result.error === "cannot_cancel") return res.status(400).json({ message: "Không thể hủy yêu cầu đã xử lý" });

    res.json({ message: "Hủy yêu cầu thành công" });
  } catch (error) {
    res.status(500).json({ message: "Hủy yêu cầu thất bại", error });
  }
};

export const leaveRide = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.userId;
    const id = p(req.params.id);

    const result = await leaveRideService(id, userId);

    if (result.error === "not_found") return res.status(404).json({ message: "Không tìm thấy chuyến đi" });
    if (result.error === "not_participant") return res.status(400).json({ message: "Bạn không tham gia chuyến đi này" });
    if (result.error === "ride_ended") return res.status(400).json({ message: "Chuyến đi đã kết thúc" });

    res.json({ message: "Rời chuyến đi thành công" });
  } catch (error) {
    res.status(500).json({ message: "Rời chuyến đi thất bại", error });
  }
};

export const removeParticipant = async (req: Request, res: Response) => {
  try {
    const ownerId = (req as any).user.userId;
    const id = p(req.params.id);
    const targetUserId = p(req.params.userId);

    const result = await removeParticipantService(id, ownerId, targetUserId);

    if (result.error === "not_found") return res.status(404).json({ message: "Không tìm thấy chuyến đi" });
    if (result.error === "forbidden") return res.status(403).json({ message: "Không có quyền" });
    if (result.error === "ride_ended") return res.status(400).json({ message: "Chuyến đi đã kết thúc" });
    if (result.error === "not_participant") return res.status(400).json({ message: "Người dùng không tham gia chuyến đi này" });

    res.json({ message: "Xóa người tham gia thành công", ride: result.ride });
  } catch (error) {
    res.status(500).json({ message: "Xóa người tham gia thất bại", error });
  }
};

// ─── STATUS ───────────────────────────────────────────────────────────────────

export const completeRide = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.userId;
    const id = p(req.params.id);

    const result = await completeRideService(id, userId);

    if (result.error === "not_found") return res.status(404).json({ message: "Không tìm thấy chuyến đi" });
    if (result.error === "forbidden") return res.status(403).json({ message: "Không có quyền" });
    if (result.error === "already_cancelled") return res.status(400).json({ message: "Chuyến đi đã bị hủy" });
    if (result.error === "already_done") return res.status(400).json({ message: "Chuyến đi đã hoàn thành" });

    res.json({ message: "Hoàn thành chuyến đi", ride: result.ride });
  } catch (error) {
    res.status(500).json({ message: "Hoàn thành chuyến đi thất bại", error });
  }
};

export const cancelRide = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.userId;
    const id = p(req.params.id);

    const result = await cancelRideService(id, userId);

    if (result.error === "not_found") return res.status(404).json({ message: "Không tìm thấy chuyến đi" });
    if (result.error === "forbidden") return res.status(403).json({ message: "Không có quyền" });
    if (result.error === "already_done") return res.status(400).json({ message: "Chuyến đi đã hoàn thành" });
    if (result.error === "already_cancelled") return res.status(400).json({ message: "Chuyến đi đã bị hủy rồi" });

    res.json({ message: "Hủy chuyến đi thành công", ride: result.ride });
  } catch (error) {
    res.status(500).json({ message: "Hủy chuyến đi thất bại", error });
  }
};
