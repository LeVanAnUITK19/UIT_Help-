import express from "express";
import { createPost, getPosts, getPostById ,getMyPosts, updatePost, deletePost } from "./post.controller";
import { authMiddleware } from "../../middleware/auth.middleware";
import { upload } from "../../middleware/upload.middleware";

const router = express.Router();

router.get("/", authMiddleware, getPosts);
router.get("/my", authMiddleware, getMyPosts);
router.get("/:id", authMiddleware, getPostById);
router.post("/", authMiddleware, upload.single("image"), createPost);
router.put("/:id", authMiddleware, upload.single("image"), updatePost);
router.delete("/:id", authMiddleware, deletePost);

export default router;
