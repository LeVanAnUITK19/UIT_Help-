class UserModel {
  final String id;
  final String name;
  final String mssv;
  final String email;

  const UserModel({required this.id, required this.name,required this.mssv, required this.email});

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as String,
    name: json['name'] as String,
    mssv: json['mssv']  as String,
    email: json['email'] as String,
  );
}
