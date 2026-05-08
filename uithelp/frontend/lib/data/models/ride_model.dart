class RideModel {
  final String id;
  final String userId;
  final String userName;
  final String type; // "find" | "offer"
  final LocationModel from;
  final LocationModel to;
  final DateTime departureTime;
  final List<ParticipantModel> participants;
  final String description;
  final String contact;
  final String status; // "active" | "full" | "done" | "cancelled"
  final DateTime createdAt;

  const RideModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.from,
    required this.to,
    required this.departureTime,
    required this.participants,
    required this.description,
    required this.contact,
    required this.status,
    required this.createdAt,
  });

  factory RideModel.fromJson(Map<String, dynamic> json) => RideModel(
        id: json['_id'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        userName: json['userName'] as String? ?? '',
        type: json['type'] as String? ?? 'find',
        from: LocationModel.fromJson(json['from'] as Map<String, dynamic>? ?? {}),
        to: LocationModel.fromJson(json['to'] as Map<String, dynamic>? ?? {}),
        departureTime: json['departureTime'] != null
            ? DateTime.tryParse(json['departureTime']) ?? DateTime.now()
            : DateTime.now(),
        participants: (json['participants'] as List<dynamic>?)
                ?.map((e) => ParticipantModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        description: json['description'] as String? ?? '',
        contact: json['contact'] as String? ?? '',
        status: json['status'] as String? ?? 'active',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
            : DateTime.now(),
      );

  bool get isFull => status == 'full';
  bool get isActive => status == 'active';
  bool get isDone => status == 'done';
  bool get isCancelled => status == 'cancelled';
  bool get isFind => type == 'find';
  bool get isOffer => type == 'offer';
}

class LocationModel {
  final String id;
  final String name;

  const LocationModel({
    required this.id,
    required this.name,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) => LocationModel(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class ParticipantModel {
  final String userId;
  final String userName;
  final DateTime joinedAt;

  const ParticipantModel({
    required this.userId,
    required this.userName,
    required this.joinedAt,
  });

  factory ParticipantModel.fromJson(Map<String, dynamic> json) =>
      ParticipantModel(
        userId: json['userId'] as String? ?? '',
        userName: json['userName'] as String? ?? '',
        joinedAt: json['joinedAt'] != null
            ? DateTime.tryParse(json['joinedAt']) ?? DateTime.now()
            : DateTime.now(),
      );
}

class RideRequestModel {
  final String id;
  final String rideId;
  final String userId;
  final String userName;
  final String message;
  final String status; // "pending" | "accepted" | "rejected"
  final DateTime createdAt;

  const RideRequestModel({
    required this.id,
    required this.rideId,
    required this.userId,
    required this.userName,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  factory RideRequestModel.fromJson(Map<String, dynamic> json) =>
      RideRequestModel(
        id: json['_id'] as String? ?? '',
        rideId: json['rideId'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        userName: json['userName'] as String? ?? '',
        message: json['message'] as String? ?? '',
        status: json['status'] as String? ?? 'pending',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
            : DateTime.now(),
      );

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
}
