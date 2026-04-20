import { Request, Response } from "express";
import Post from "./post.model";
import cloudinary from "../../config/cloudinary";import "../../middleware/upload.middleware";


//CREATE POST
export const createPost = async (req: Request, res: Response) => {
    try {
        const { type, title, description, location, contact } = req.body;

        const userId = (req as any).user.userId; // từ JWT middleware
        let imageUrl = "";

        if (req.file)  {
            const result = await cloudinary.uploader.upload_stream(
                { folder: "uit_help" },
                (error: any, result: any) => {
                    if (error) throw error;
                    imageUrl = result.secure_url;
                }
            );

            // convert buffer → stream
            const streamifier = require("streamifier");
            streamifier.createReadStream(req.file.buffer).pipe(result);
        }

        const post = await Post.create({
            userId,
            type,
            title,
            description,
            location,
            contact,
            imageUrl,
            status: type === "lost" ? "searching" : "unclaimed",
        });

        res.status(201).json(post);
    } catch (error) {
        res.status(500).json({ message: "Create post failed", error });
    }
};