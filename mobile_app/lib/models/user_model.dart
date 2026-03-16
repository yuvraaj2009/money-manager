class UserModel {
  final String id;
  final String email;
  final String name;
  final String? pictureUrl;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.pictureUrl,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      pictureUrl: json['picture_url'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
