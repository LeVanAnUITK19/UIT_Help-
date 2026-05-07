class MatchedPostModel {
  final String id;
  final String userName;
  final String type;
  final String title;
  final String description;
  final String location;
  final String imageUrl;
  final String status;
  final int score;

  const MatchedPostModel({
    required this.id,
    required this.userName,
    required this.type,
    required this.title,
    required this.description,
    required this.location,
    required this.imageUrl,
    required this.status,
    required this.score,
  });

  factory MatchedPostModel.fromJson(Map<String, dynamic> json) {
    final post = json['post'] as Map<String, dynamic>? ?? json;
    return MatchedPostModel(
      id: post['_id'] as String? ?? '',
      userName: post['userName'] as String? ?? '',
      type: post['type'] as String? ?? '',
      title: post['title'] as String? ?? '',
      description: post['description'] as String? ?? '',
      location: post['location'] as String? ?? '',
      imageUrl: post['imageUrl'] as String? ?? '',
      status: post['status'] as String? ?? '',
      score: (json['score'] as num?)?.toInt() ?? 0,
    );
  }
}

class PostModel {
  final String id;
  final String userId;
  final String userName;
  final String type;
  final String title;
  final String description;
  final String location;
  final String contact;
  final String imageUrl;
  final int commentCount;
  final String status;
  final DateTime createdAt;
  final List<MatchedPostModel> matches;

  const PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.title,
    required this.description,
    required this.location,
    required this.contact,
    required this.imageUrl,
    required this.commentCount,
    required this.status,
    required this.createdAt,
    this.matches = const [],
  });

  factory PostModel.fromJson(Map<String, dynamic> json) => PostModel(
        id: json['_id'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        userName: json['userName'] as String? ?? '',
        type: json['type'] as String? ?? 'lost',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        location: json['location'] as String? ?? '',
        contact: json['contact'] as String? ?? '',
        imageUrl: json['imageUrl'] as String? ?? '',
        commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
        status: json['status'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
            : DateTime.now(),
        matches: (json['match'] as List<dynamic>?)
                ?.map((e) => MatchedPostModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  PostModel copyWith({int? commentCount}) => PostModel(
        id: id,
        userId: userId,
        userName: userName,
        type: type,
        title: title,
        description: description,
        location: location,
        contact: contact,
        imageUrl: imageUrl,
        commentCount: commentCount ?? this.commentCount,
        status: status,
        createdAt: createdAt,
        matches: matches,
      );
}
