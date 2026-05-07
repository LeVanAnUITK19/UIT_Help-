class ConversationModel {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final Map<String, int> unreadCount;

  const ConversationModel({
    required this.id,
    required this.participants,
    required this.lastMessage,
    this.lastMessageAt,
    required this.unreadCount,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final raw = json['unreadCount'] as Map<String, dynamic>? ?? {};
    return ConversationModel(
      id: json['_id'] as String? ?? '',
      participants: (json['participants'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      lastMessage: json['lastMessage'] as String? ?? '',
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'].toString())
          : null,
      unreadCount: raw.map((k, v) => MapEntry(k, (v as num).toInt())),
    );
  }

  int unreadFor(String userId) => unreadCount[userId] ?? 0;

  String otherParticipant(String myId) =>
      participants.firstWhere((p) => p != myId, orElse: () => '');
}

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final String type; // text | image
  final bool isRead;
  final bool isDeleted;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.isRead,
    required this.isDeleted,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
        id: json['_id'] as String? ?? '',
        conversationId: json['conversationId'] as String? ?? '',
        senderId: json['senderId'] as String? ?? '',
        content: json['content'] as String? ?? '',
        type: json['type'] as String? ?? 'text',
        isRead: json['isRead'] as bool? ?? false,
        isDeleted: json['isDeleted'] as bool? ?? false,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
}
