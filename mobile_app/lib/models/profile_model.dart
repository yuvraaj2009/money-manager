class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.name,
    required this.monthlyIncome,
    required this.currency,
    required this.householdMembers,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final int monthlyIncome;
  final String currency;
  final int householdMembers;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get monthlyIncomeRupees => monthlyIncome / 100;

  factory ProfileModel.empty() {
    final now = DateTime.now();
    return ProfileModel(
      id: '',
      name: 'My Household',
      monthlyIncome: 0,
      currency: 'INR',
      householdMembers: 2,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    final monthlyIncome = (json['monthly_income'] as num?)?.toInt() ?? 0;
    return ProfileModel(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? 'My Household',
      monthlyIncome: monthlyIncome,
      currency: (json['currency'] as String?) ?? 'INR',
      householdMembers: (json['household_members'] as num?)?.toInt() ?? 1,
      createdAt:
          DateTime.tryParse((json['created_at'] as String?) ?? '') ?? now,
      updatedAt:
          DateTime.tryParse((json['updated_at'] as String?) ?? '') ?? now,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'monthly_income': monthlyIncome,
      'currency': currency,
      'household_members': householdMembers,
    };
  }

  ProfileModel copyWith({
    String? id,
    String? name,
    int? monthlyIncome,
    String? currency,
    int? householdMembers,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      currency: currency ?? this.currency,
      householdMembers: householdMembers ?? this.householdMembers,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
