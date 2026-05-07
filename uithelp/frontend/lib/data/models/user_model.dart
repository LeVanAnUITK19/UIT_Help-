class UserModel {
  final String id;
  final String name;
  final String mssv;
  final String email;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.mssv,
    required this.email,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as String? ?? json['_id'] as String? ?? '',
    name: json['name'] as String,
    mssv: json['mssv'] as String,
    email: json['email'] as String,
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'].toString())
        : null,
  );
}
