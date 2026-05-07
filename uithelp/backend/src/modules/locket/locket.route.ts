import express from "express";
import {
    createLocket,
    getLockets,
    getMyLockets,
    deleteLocket,
    reactToLocket,
    getReactionsOfLocket,
    commentOnLocket,
    getCommentsOfLocket,
} from "./locket.controller";
import { authMiddleware } from "../../middleware/auth.middleware";
import { upload } from "../../middleware/upload.middleware";

const router = express.Router();

// Locket
router.get("/", authMiddleware, getLockets);
router.get("/my", authMiddleware, getMyLockets);
router.post("/", authMiddleware, upload.single("image"), createLocket);
router.delete("/:id", authMiddleware, deleteLocket);

// Reactions
router.post("/:id/reactions", authMiddleware, reactToLocket);
router.get("/:id/reactions", authMiddleware, getReactionsOfLocket);

// Comments
router.post("/:id/comments", authMiddleware, commentOnLocket);
router.get("/:id/comments", authMiddleware, getCommentsOfLocket);

export default router;
