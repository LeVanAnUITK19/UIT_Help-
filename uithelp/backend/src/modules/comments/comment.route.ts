import express from "express";
import { createComment, getComment, deleteComment } from "./comment.controller";
import { authMiddleware } from "../../middleware/auth.middleware";

const router = express.Router();

router.get("/:postId", authMiddleware, getComment);
router.post("/", authMiddleware, createComment);
router.delete("/:id", authMiddleware, deleteComment);

export default router;