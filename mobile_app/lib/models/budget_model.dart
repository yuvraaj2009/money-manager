class BudgetModel {
  const BudgetModel({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.categoryIcon,
    required this.monthlyLimit,
    required this.spentAmount,
    required this.remainingAmount,
    required this.utilizationPercentage,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String categoryId;
  final String categoryName;
  final String categoryColor;
  final String categoryIcon;
  final int monthlyLimit;
  final int spentAmount;
  final int remainingAmount;
  final double utilizationPercentage;
  final String status;
  final DateTime createdAt;

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: '${json['id'] ?? ''}',
      categoryId: (json['category_id'] ?? json['category'] ?? 'budget') as String,
      categoryName: (json['category_name'] ?? json['category'] ?? 'Budget') as String,
      categoryColor: (json['category_color'] as String?) ?? '#0F52FF',
      categoryIcon: (json['category_icon'] as String?) ?? 'account_balance_wallet',
      monthlyLimit: (json['monthly_limit'] as num?)?.toInt() ?? 0,
      spentAmount: (json['spent_amount'] as num?)?.toInt() ?? 0,
      remainingAmount: (json['remaining_amount'] as num?)?.toInt() ?? 0,
      utilizationPercentage: (json['utilization_percentage'] as num?)?.toDouble() ?? 0,
      status: (json['status'] as String?) ?? 'safe',
      createdAt: DateTime.parse(
        (json['created_at'] as String?) ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

class BudgetAlertModel {
  const BudgetAlertModel({
    required this.categoryId,
    required this.categoryName,
    required this.spentAmount,
    required this.monthlyLimit,
    required this.overAmount,
    required this.utilizationPercentage,
    required this.severity,
  });

  final String categoryId;
  final String categoryName;
  final int spentAmount;
  final int monthlyLimit;
  final int overAmount;
  final double utilizationPercentage;
  final String severity;

  factory BudgetAlertModel.fromJson(Map<String, dynamic> json) {
    return BudgetAlertModel(
      categoryId: (json['category_id'] ?? json['category_name'] ?? 'budget') as String,
      categoryName: (json['category_name'] as String?) ?? 'Budget',
      spentAmount: (json['spent_amount'] as num?)?.toInt() ?? 0,
      monthlyLimit: (json['monthly_limit'] as num?)?.toInt() ?? 0,
      overAmount: (json['over_amount'] as num?)?.toInt() ?? 0,
      utilizationPercentage: (json['utilization_percentage'] as num?)?.toDouble() ?? 0,
      severity: (json['severity'] as String?) ?? 'medium',
    );
  }
}

class DailySpendBarModel {
  const DailySpendBarModel({
    required this.label,
    required this.amount,
    required this.isToday,
  });

  final String label;
  final int amount;
  final bool isToday;

  factory DailySpendBarModel.fromJson(Map<String, dynamic> json) {
    return DailySpendBarModel(
      label: (json['label'] as String?) ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      isToday: json['is_today'] as bool? ?? false,
    );
  }
}

class BudgetUtilizationModel {
  const BudgetUtilizationModel({
    required this.month,
    required this.year,
    required this.totalBudget,
    required this.totalSpent,
    required this.utilizationPercentage,
    required this.alerts,
    required this.budgets,
    required this.dailySpend,
  });

  final int month;
  final int year;
  final int totalBudget;
  final int totalSpent;
  final double utilizationPercentage;
  final List<BudgetAlertModel> alerts;
  final List<BudgetModel> budgets;
  final List<DailySpendBarModel> dailySpend;

  factory BudgetUtilizationModel.fromJson(Map<String, dynamic> json) {
    return BudgetUtilizationModel(
      month: (json['month'] as num?)?.toInt() ?? DateTime.now().month,
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
      totalBudget: (json['total_budget'] as num?)?.toInt() ?? 0,
      totalSpent: (json['total_spent'] as num?)?.toInt() ?? 0,
      utilizationPercentage: (json['utilization_percentage'] as num?)?.toDouble() ?? 0,
      alerts: (json['alerts'] as List<dynamic>? ?? const [])
          .map((item) => BudgetAlertModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      budgets: (json['budgets'] as List<dynamic>? ?? const [])
          .map((item) => BudgetModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      dailySpend: (json['daily_spend'] as List<dynamic>? ?? const [])
          .map((item) => DailySpendBarModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
