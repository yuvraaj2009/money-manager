class HouseholdMemberModel {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String role;
  final DateTime joinedAt;

  const HouseholdMemberModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.role,
    required this.joinedAt,
  });

  factory HouseholdMemberModel.fromJson(Map<String, dynamic> json) {
    return HouseholdMemberModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      userName: json['user_name'] as String? ?? '',
      userEmail: json['user_email'] as String? ?? '',
      role: json['role'] as String? ?? 'member',
      joinedAt: DateTime.tryParse(json['joined_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class HouseholdModel {
  final String id;
  final String name;
  final String inviteCode;
  final String createdBy;
  final DateTime createdAt;
  final List<HouseholdMemberModel> members;

  const HouseholdModel({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.createdBy,
    required this.createdAt,
    this.members = const [],
  });

  factory HouseholdModel.fromJson(Map<String, dynamic> json) {
    final membersList = json['members'] as List<dynamic>? ?? [];
    return HouseholdModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      inviteCode: json['invite_code'] as String? ?? '',
      createdBy: json['created_by'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      members: membersList
          .map((m) =>
              HouseholdMemberModel.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}
