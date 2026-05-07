import Conversation from "./conversation.model";
import Message from "./message.model";

/**
 * Lấy tổng số unread messages của một user trên tất cả conversations
 */
export const getTotalUnreadCount = async (userId: string): Promise<number> => {
  const conversations = await Conversation.find({ participants: userId });
  let total = 0;
  for (const conv of conversations) {
    const unreadMap = conv.unreadCount as Map<string, number>;
    total += unreadMap.get(userId) ?? 0;
  }
  return total;
};

/**
 * Xóa toàn bộ messages và conversation (dùng cho cleanup/admin)
 */
export const deleteConversation = async (
  conversationId: string,
  userId: string
): Promise<{ success: boolean; message: string }> => {
  const conversation = await Conversation.findById(conversationId);
  if (!conversation) return { success: false, message: "Không tìm thấy" };
  if (!conversation.participants.includes(userId)) {
    return { success: false, message: "Không có quyền" };
  }
  await Message.deleteMany({ conversationId });
  await Conversation.findByIdAndDelete(conversationId);
  return { success: true, message: "Đã xóa conversation" };
};
