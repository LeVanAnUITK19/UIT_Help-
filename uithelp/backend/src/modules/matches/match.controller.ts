import { Request, Response } from "express";
import Post from "../posts/post.model";
import User from "../auth/auth.model";
import Match from "../matches/match.model";
import { sendPush } from "../../utils/sendPushNotification";
import { createNotification } from "../notifications/notification.service";

/**
 * Tính toán độ tương đồng giữa 2 chuỗi (Dice's Coefficient)
 * Trả về giá trị từ 0 đến 1
 */
const stringSimilarity = (str1: string, str2: string): number => {
  const s1 = str1.replace(/\s+/g, "").toLowerCase();
  const s2 = str2.replace(/\s+/g, "").toLowerCase();
  if (s1 === s2) return 1;
  if (s1.length < 2 || s2.length < 2) return 0;

  const bigrams1 = new Map();
  for (let i = 0; i < s1.length - 1; i++) {
    const bigram = s1.substring(i, i + 2);
    bigrams1.set(bigram, (bigrams1.get(bigram) || 0) + 1);
  }

  let intersection = 0;
  for (let i = 0; i < s2.length - 1; i++) {
    const bigram = s2.substring(i, i + 2);
    const count = bigrams1.get(bigram) || 0;
    if (count > 0) {
      bigrams1.set(bigram, count - 1);
      intersection++;
    }
  }

  return (2 * intersection) / (s1.length + s2.length - 2);
};

const calculateScoreAdvanced = (a: any, b: any) => {
  let totalScore = 0;

  // 1. 📍 Địa điểm (Trọng số: 30)
  // Nếu bạn có tọa độ (lat/long), nên tính theo khoảng cách bán kính. 
  // Ở đây giả định so sánh text:
  if (a.location && b.location) {
    const locSim = stringSimilarity(a.location, b.location);
    if (locSim > 0.8) totalScore += 30; // Coi như khớp vùng miền
    else totalScore += locSim * 20;
  }

  // 2. 📝 Nội dung văn bản (Trọng số: 40)
  // Kết hợp Title và Description, tính tỷ lệ tương đồng
  const textA = `${a.title} ${a.description || ""}`.trim();
  const textB = `${b.title} ${b.description || ""}`.trim();
  
  const textSim = stringSimilarity(textA, textB);
  totalScore += textSim * 40; 

  // 3. 🖼 Image Tags (Trọng số: 20)
  // Sử dụng Jaccard Similarity: (Trùng lặp) / (Tổng số tag không trùng)
  if (a.imageTags?.length && b.imageTags?.length) {
    const setA = new Set(a.imageTags);
    const setB = new Set(b.imageTags);
    const intersection = new Set([...setA].filter(x => setB.has(x)));
    const union = new Set([...setA, ...setB]);
    
    const jaccardIndex = intersection.size / union.size;
    totalScore += jaccardIndex * 20;
  }

  // 4. ⏰ Thời gian (Trọng số: 10)
  // Sử dụng hàm suy giảm mũ để điểm giảm dần theo thời gian thay vì nhảy bậc
  const diffInDays = Math.abs(
    new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime()
  ) / (1000 * 60 * 60 * 24);

  // Công thức: 10 điểm * e^(-0.5 * số ngày)
  // Cách này giúp 0 ngày = 10đ, 2 ngày ≈ 3.6đ, 7 ngày ≈ 0.3đ
  const timeScore = 10 * Math.exp(-0.5 * diffInDays);
  totalScore += timeScore;

  return Math.round(totalScore);
};

export const matchPost = async (newPost: any) => {
  try {
    const targetType = newPost.type === "lost" ? "found" : "lost";
    const twoDaysAgo = new Date();
    twoDaysAgo.setDate(twoDaysAgo.getDate() - 2);

    // Chỉ lấy bài đang "active": lost→searching, found→unclaimed
    const activeStatus = targetType === "lost" ? "searching" : "unclaimed";

    const candidates = await Post.find({
      type: targetType,
      isDeleted: false,
      status: activeStatus,
      createdAt: { $gte: twoDaysAgo },
      _id: { $ne: newPost._id },
    });

    const results = [];

    for (const post of candidates) {
      // Tính toán chi tiết từng phần để biết "khớp vì cái gì"
      
      // 1. Location Score
      const locSim = newPost.location && post.location ? stringSimilarity(newPost.location, post.location) : 0;
      const locScore = locSim > 0.8 ? 30 : locSim * 20;

      // 2. Text Score
      const textA = `${newPost.title} ${newPost.description || ""}`.trim();
      const textB = `${post.title} ${post.description || ""}`.trim();
      const textSim = stringSimilarity(textA, textB);
      const textScore = textSim * 40;

      // 3. Image Score
      let imageScore = 0;
      if (newPost.imageTags?.length && post.imageTags?.length) {
        const setA = new Set<string>(newPost.imageTags);
        const setB = new Set<string>(post.imageTags);
        const intersection = new Set<string>([...setA].filter(x => setB.has(x)));
        const union = new Set<string>([...setA, ...setB]);
        imageScore = (intersection.size / union.size) * 20;
      }

      // 4. Time Score
      const diffInDays = Math.abs(new Date(newPost.createdAt).getTime() - new Date(post.createdAt).getTime()) / (1000 * 60 * 60 * 24);
      const timeScore = 10 * Math.exp(-0.5 * diffInDays);

      const totalScore = Math.round(locScore + textScore + imageScore + timeScore);

      // Hạ ngưỡng xuống 30 để không bỏ sót match tiềm năng
      if (totalScore >= 30) {
        results.push({ 
          post, 
          score: totalScore,
          // Lưu trạng thái khớp chi tiết
          details: {
            location: locSim > 0.7, // Coi là khớp nếu giống trên 70%
            text: textSim > 0.5,     // Khớp nội dung nếu tương đồng trên 50%
            image: imageScore > 10,  // Khớp ảnh nếu chung nhau kha khá tag
            time: diffInDays <= 1    // Khớp thời gian nếu trong vòng 24h
          }
        });
      }
    }

    results.sort((a, b) => b.score - a.score);
    const topMatches = results.slice(0, 5);

    await Promise.all(
      topMatches.map((m) =>
        Match.findOneAndUpdate(
          { postA: newPost._id, postB: m.post._id },
          {
            $set: {
              score: m.score,
              matchedFields: m.details,
            }
          },
          { upsert: true, new: true }
        )
      )
    );

    // Gửi push + internal notification cho chủ bài đăng nếu có match điểm cao nhất
    if (topMatches.length > 0) {
      const best = topMatches[0];
      const owner = await User.findById(newPost.userId);
      if (owner?.fcmToken) {
        await sendPush(
          owner.fcmToken,
          "🔍 Có bài viết liên quan!",
          `Bài "${newPost.title}" khớp ${best.score}đ với một bài đăng khác`,
          { type: "match", postId: newPost._id.toString() }
        );
      }
      await createNotification({
        userId: newPost.userId.toString(),
        type: "match",
        title: "🔍 Tìm thấy bài viết liên quan!",
        message: `Bài "${newPost.title}" có thể khớp với một bài đăng khác (${best.score} điểm)`,
        postId: newPost._id.toString(),
      });

      // Thông báo cho chủ bài kia (postB)
      const matchedPost = best.post as any;
      if (matchedPost?.userId) {
        const otherOwner = await User.findById(matchedPost.userId);
        if (otherOwner?.fcmToken) {
          await sendPush(
            otherOwner.fcmToken,
            "🔍 Có bài viết liên quan!",
            `Bài "${matchedPost.title}" có thể khớp với một bài đăng mới`,
            { type: "match", postId: matchedPost._id?.toString() }
          );
        }
        await createNotification({
          userId: matchedPost.userId.toString(),
          type: "match",
          title: "🔍 Tìm thấy bài viết liên quan!",
          message: `Bài "${matchedPost.title}" có thể khớp với một bài đăng mới (${best.score} điểm)`,
          postId: matchedPost._id?.toString(),
        });
      }
    }

    return topMatches;
  } catch (err) {
    console.error("Match error:", err);
    return [];
  }
};

 