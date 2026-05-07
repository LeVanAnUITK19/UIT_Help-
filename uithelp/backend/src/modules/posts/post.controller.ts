import { Request, Response } from "express";
import Post from "./post.model";
import cloudinary from "../../config/cloudinary";
import streamifier from "streamifier";
import User from "../auth/auth.model";
import { analyzeImage } from "../../utils/analyzeImage";
import { matchPost } from "../matches/match.controller";
import Match from "../matches/match.model";

const uploadToCloudinary = (buffer: Buffer): Promise<string> => {
    return new Promise((resolve, reject) => {
        const stream = cloudinary.uploader.upload_stream(
            { folder: "uit_help" },
            (error, result) => {
                if (error || !result) return reject(error);
                resolve(result.secure_url);
            }
        );
        streamifier.createReadStream(buffer).pipe(stream);
    });
};

export const createPost = async (req: Request, res: Response) => {
    try {
        const { type, title, description, location, contact } = req.body;
        const userId = (req as any).user.userId;
        const user = await User.findById(userId);

        let imageUrl = "";
        let imageTags: string[] = [];
        if (req.file) {
            imageUrl = await uploadToCloudinary(req.file.buffer);

            //const aiResult = await analyzeImage(imageUrl); 
            //imageTags = aiResult.tags; 
            imageTags=["wallet", "black", "accessory"];
        }
        
        const post = await Post.create({
            userId,
            userName: user?.name,
            type,
            title,
            description,
            location,
            contact,
            imageUrl,
            commentCount: 0,
            imageTags,
            status: type === "lost" ? "searching" : "unclaimed",
        });
        const match = await matchPost(post.toObject());

        res.status(201).json({ ...post.toObject(), match, commentCount: 0 });
    } catch (error) {
        res.status(500).json({ message: "Create post failed", error });
    }
};

export const getPosts = async (req: Request, res: Response) => {
    try {
        const limit = 10;
        const { cursor } = req.query;
        const filter: any = { isDeleted: false };
        if (cursor) filter._id = { $lt: cursor };

        const posts = await Post.find(filter).sort({ _id: -1 }).limit(limit);
        const nextCursor = posts.length === limit ? posts[posts.length - 1]._id : null;

        res.json({ posts, nextCursor });
    } catch (error) {
        res.status(500).json({ message: "Get posts failed", error });
    }
};
export const getPostById = async (req: Request, res: Response) => {
    try {
        const { id } = req.params;

        const post = await Post.findOne({ _id: id, isDeleted: false });
        if (!post) {
            return res.status(404).json({ message: "Khong tim thay bai" });
        }

        // Lấy match liên quan (nếu có)
        const matches = await Match.find({ postA: post._id })
            .populate("postB")
            .lean();

        const match = matches.map((m) => ({
            post: m.postB,
            score: m.score,
        }));

        res.json({
            ...post.toObject(),
            match,
        });
    } catch (error) {
        res.status(500).json({ message: "Get post failed", error });
    }
};

export const getMyPosts = async (req: Request, res: Response) => {
    try {
        const userId = (req as any).user.userId;
        const limit = 10;
        const { cursor } = req.query;
        const filter: any = { isDeleted: false, userId };
        if (cursor) filter._id = { $lt: cursor };

        const posts = await Post.find(filter).sort({ _id: -1 }).limit(limit);
        const nextCursor = posts.length === limit ? posts[posts.length - 1]._id : null;

        // Lấy matches cho từng post
        const postIds = posts.map((p) => p._id);
        const matches = await Match.find({ postA: { $in: postIds } })
            .populate("postB")
            .lean();

        // Gom matches theo postA
        const matchMap = new Map<string, any[]>();
        for (const m of matches) {
            const key = m.postA.toString();
            if (!matchMap.has(key)) matchMap.set(key, []);
            matchMap.get(key)!.push({ post: m.postB, score: m.score });
        }

        const postsWithMatch = posts.map((p) => ({
            ...p.toObject(),
            match: matchMap.get(p._id.toString()) ?? [],
        }));

        res.json({ posts: postsWithMatch, nextCursor });
    } catch (error) {
        res.status(500).json({ message: "Get my posts failed", error });
    }
};

export const updatePost = async (req: Request, res: Response) => {
    try {
        const userId = (req as any).user.userId;
        const { id } = req.params;
        const { title, description, location, contact, status } = req.body;

        const post = await Post.findOne({ _id: id, isDeleted: false });
        if (!post) return res.status(404).json({ message: "Khong tim thay bai" });
        if (post.userId.toString() !== userId) return res.status(403).json({ message: "Khong co quyen" });

        if (req.file) post.imageUrl = await uploadToCloudinary(req.file.buffer);
        if (title) post.title = title;
        if (description) post.description = description;
        if (location) post.location = location;
        if (contact) post.contact = contact;
        if (status) post.status = status;

        await post.save();
        res.json(post);
    } catch (error) {
        res.status(500).json({ message: "Update post failed", error });
    }
};

export const deletePost = async (req: Request, res: Response) => {
    try {
        const userId = (req as any).user.userId;
        const { id } = req.params;

        const post = await Post.findOne({ _id: id, isDeleted: false });
        if (!post) return res.status(404).json({ message: "Khong tim thay bai" });
        if (post.userId.toString() !== userId) return res.status(403).json({ message: "Khong co quyen" });

        post.isDeleted = true;
        post.deletedAt = new Date();
        await post.save();

        res.json({ message: "Xoa thanh cong" });
    } catch (error) {
        res.status(500).json({ message: "Delete post failed", error });
    }
};
