class NotificationModel {
  final String id;
  final String userId;
  final String type; // match | comment | reaction | ride_join
  final String title;
  final String? message;
  final String? postId;
  final String? locketId;
  final String? senderId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.message,
    this.postId,
    this.locketId,
    this.senderId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['_id'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        type: json['type'] as String? ?? '',
        title: json['title'] as String? ?? '',
        message: json['message'] as String?,
        postId: json['postId'] as String?,
        locketId: json['locketId'] as String?,
        senderId: json['senderId'] as String?,
        isRead: json['isRead'] as bool? ?? false,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        id: id,
        userId: userId,
        type: type,
        title: title,
        message: message,
        postId: postId,
        locketId: locketId,
        senderId: senderId,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );
}
