class CommentModel {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String content;
  final DateTime createdAt;

  const CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    required this.content,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) => CommentModel(
    id: json['_id'] as String? ?? '',
    postId: json['postId'] as String? ?? '',
    userId: json['userId'] as String? ?? '',
    userName: json['userName'] as String? ?? '',
    content: json['content'] as String? ?? '',
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
        : DateTime.now(),
  );
}
