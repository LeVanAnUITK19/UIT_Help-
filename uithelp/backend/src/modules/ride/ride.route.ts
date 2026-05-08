import express from "express";
import { authMiddleware } from "../../middleware/auth.middleware";
import {
  createRide,
  getRides,
  getRideById,
  updateRide,
  deleteRide,
  requestJoinRide,
  getRideRequests,
  acceptRideRequest,
  rejectRideRequest,
  getMatchedRides,
  getMyRides,
  getJoinedRides,
  getMyRideRequests,
  cancelRideRequest,
  leaveRide,
  removeParticipant,
  completeRide,
  cancelRide,
} from "./ride.controller";

const router = express.Router();

// ─── RIDE CRUD ────────────────────────────────────────────────────────────────
// GET  /api/rides              → danh sách (filter: type, fromId, toId, status, cursor)
// GET  /api/rides/my           → chuyến đi tôi tạo
// GET  /api/rides/joined       → chuyến đi tôi đã tham gia
// GET  /api/rides/:id          → chi tiết
// POST /api/rides              → tạo mới
// PUT  /api/rides/:id          → cập nhật
// DELETE /api/rides/:id        → xóa mềm

router.get("/my", authMiddleware, getMyRides);
router.get("/joined", authMiddleware, getJoinedRides);
router.get("/", authMiddleware, getRides);
router.get("/:id", authMiddleware, getRideById);
router.post("/", authMiddleware, createRide);
router.put("/:id", authMiddleware, updateRide);
router.delete("/:id", authMiddleware, deleteRide);

// ─── JOIN / REQUEST ───────────────────────────────────────────────────────────
// POST   /api/rides/:id/request              → gửi yêu cầu tham gia
// GET    /api/rides/:id/requests             → xem danh sách yêu cầu (chủ xe)
// PATCH  /api/rides/requests/:requestId/accept → chấp nhận
// PATCH  /api/rides/requests/:requestId/reject → từ chối
// DELETE /api/rides/requests/:requestId      → hủy yêu cầu (người gửi)
// DELETE /api/rides/:id/leave                → rời chuyến đi
// DELETE /api/rides/:id/participants/:userId → chủ xe xóa người tham gia

router.post("/:id/request", authMiddleware, requestJoinRide);
router.get("/:id/requests", authMiddleware, getRideRequests);
router.patch("/requests/:requestId/accept", authMiddleware, acceptRideRequest);
router.patch("/requests/:requestId/reject", authMiddleware, rejectRideRequest);
router.delete("/requests/:requestId", authMiddleware, cancelRideRequest);
router.delete("/:id/leave", authMiddleware, leaveRide);
router.delete("/:id/participants/:userId", authMiddleware, removeParticipant);

// ─── MATCHING ─────────────────────────────────────────────────────────────────
// GET /api/rides/:id/matches → tìm chuyến đi ngược chiều phù hợp

router.get("/:id/matches", authMiddleware, getMatchedRides);

// ─── MY REQUESTS ─────────────────────────────────────────────────────────────
// GET /api/rides/me/requests → các yêu cầu tôi đã gửi

router.get("/me/requests", authMiddleware, getMyRideRequests);

// ─── STATUS ───────────────────────────────────────────────────────────────────
// PATCH /api/rides/:id/complete → hoàn thành
// PATCH /api/rides/:id/cancel   → hủy

router.patch("/:id/complete", authMiddleware, completeRide);
router.patch("/:id/cancel", authMiddleware, cancelRide);

export default router;
