class LocketModel {
  final String id;
  final String userId;
  final String userName;
  final String imageUrl;
  final String? caption;
  final int reactionsCount;
  final DateTime createdAt;

  const LocketModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.imageUrl,
    this.caption,
    required this.reactionsCount,
    required this.createdAt,
  });

  factory LocketModel.fromJson(Map<String, dynamic> json) => LocketModel(
        id: json['_id'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        userName: json['userName'] as String? ?? '',
        imageUrl: json['imageUrl'] as String? ?? '',
        caption: json['caption'] as String?,
        reactionsCount: (json['reactionsCount'] as num?)?.toInt() ?? 0,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
            : DateTime.now(),
      );
}

class LocketReactionModel {
  final String id;
  final String userId;
  final String userName;
  final String type;

  const LocketReactionModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
  });

  factory LocketReactionModel.fromJson(Map<String, dynamic> json) =>
      LocketReactionModel(
        id: json['_id'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        userName: json['userName'] as String? ?? '',
        type: json['type'] as String? ?? 'like',
      );
}

class LocketCommentModel {
  final String id;
  final String userId;
  final String userName;
  final String content;
  final DateTime createdAt;

  const LocketCommentModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.content,
    required this.createdAt,
  });

  factory LocketCommentModel.fromJson(Map<String, dynamic> json) =>
      LocketCommentModel(
        id: json['_id'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        userName: json['userName'] as String? ?? '',
        content: json['content'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
            : DateTime.now(),
      );
}
