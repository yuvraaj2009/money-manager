class MonthlySummaryModel {
  const MonthlySummaryModel({
    required this.month,
    required this.year,
    required this.monthlyTotal,
    required this.totalSpending,
    required this.totalIncome,
    required this.netCashFlow,
    required this.transactionCount,
    required this.weeklyBurnRate,
    required this.budgetAlertCount,
    required this.topCategory,
    required this.insight,
  });

  final int month;
  final int year;
  final int monthlyTotal;
  final int totalSpending;
  final int totalIncome;
  final int netCashFlow;
  final int transactionCount;
  final int weeklyBurnRate;
  final int budgetAlertCount;
  final String topCategory;
  final String insight;

  int get incomeTotal => totalIncome;
  int get expenseTotal => totalSpending;

  factory MonthlySummaryModel.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    final incomeTotal = (json['total_income'] ?? json['income_total'] ?? 0) as num;
    final expenseTotal = (json['total_spending'] ?? json['expense_total'] ?? 0) as num;
    final netCashFlow = (json['net_cash_flow'] ?? (incomeTotal.toInt() - expenseTotal.toInt())) as num;

    return MonthlySummaryModel(
      month: (json['month'] ?? now.month) as int,
      year: (json['year'] ?? now.year) as int,
      monthlyTotal: (json['monthly_total'] ?? (incomeTotal.toInt() + expenseTotal.toInt())) as int,
      totalSpending: expenseTotal.toInt(),
      totalIncome: incomeTotal.toInt(),
      netCashFlow: netCashFlow.toInt(),
      transactionCount: (json['transaction_count'] ?? 0) as int,
      weeklyBurnRate: (json['weekly_burn_rate'] ?? 0) as int,
      budgetAlertCount: (json['budget_alert_count'] ?? 0) as int,
      topCategory: (json['top_category'] ?? 'Other') as String,
      insight: (json['insight'] as String?) ?? 'Summary available for this period.',
    );
  }

  Map<String, dynamic> toJson() => {
        'month': month,
        'year': year,
        'monthly_total': monthlyTotal,
        'total_spending': totalSpending,
        'total_income': totalIncome,
        'net_cash_flow': netCashFlow,
        'transaction_count': transactionCount,
        'weekly_burn_rate': weeklyBurnRate,
        'budget_alert_count': budgetAlertCount,
        'top_category': topCategory,
        'insight': insight,
      };
}

class TrendPointModel {
  const TrendPointModel({
    required this.month,
    required this.label,
    required this.totalSpending,
    required this.totalIncome,
    required this.netFlow,
  });

  final int month;
  final String label;
  final int totalSpending;
  final int totalIncome;
  final int netFlow;

  factory TrendPointModel.fromJson(Map<String, dynamic> json) {
    return TrendPointModel(
      month: (json['month'] as num?)?.toInt() ?? 0,
      label: (json['label'] as String?) ?? '',
      totalSpending: (json['total_spending'] as num?)?.toInt() ?? 0,
      totalIncome: (json['total_income'] as num?)?.toInt() ?? 0,
      netFlow: (json['net_flow'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'month': month,
        'label': label,
        'total_spending': totalSpending,
        'total_income': totalIncome,
        'net_flow': netFlow,
      };
}

class YearSummaryModel {
  const YearSummaryModel({
    required this.year,
    required this.totalSpending,
    required this.totalIncome,
    required this.netCashFlow,
    required this.averageMonthlySpending,
    required this.monthlyBreakdown,
  });

  final int year;
  final int totalSpending;
  final int totalIncome;
  final int netCashFlow;
  final int averageMonthlySpending;
  final List<TrendPointModel> monthlyBreakdown;

  factory YearSummaryModel.fromJson(Map<String, dynamic> json) {
    return YearSummaryModel(
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
      totalSpending: (json['total_spending'] as num?)?.toInt() ?? 0,
      totalIncome: (json['total_income'] as num?)?.toInt() ?? 0,
      netCashFlow: (json['net_cash_flow'] as num?)?.toInt() ?? 0,
      averageMonthlySpending: (json['average_monthly_spending'] as num?)?.toInt() ?? 0,
      monthlyBreakdown: (json['monthly_breakdown'] as List<dynamic>? ?? const [])
          .map((item) => TrendPointModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'year': year,
        'total_spending': totalSpending,
        'total_income': totalIncome,
        'net_cash_flow': netCashFlow,
        'average_monthly_spending': averageMonthlySpending,
        'monthly_breakdown': monthlyBreakdown.map((t) => t.toJson()).toList(),
      };
}

class CategoryAnalyticsModel {
  const CategoryAnalyticsModel({
    required this.categoryId,
    required this.name,
    required this.color,
    required this.icon,
    required this.totalAmount,
    required this.percentage,
  });

  final String categoryId;
  final String name;
  final String color;
  final String icon;
  final int totalAmount;
  final double percentage;

  factory CategoryAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return CategoryAnalyticsModel(
      categoryId: (json['category_id'] ?? json['id'] ?? json['name']) as String,
      name: (json['name'] ?? json['category'] ?? 'Other') as String,
      color: (json['color'] as String?) ?? '#0F52FF',
      icon: (json['icon'] as String?) ?? 'account_balance_wallet',
      totalAmount: (json['total_amount'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'category_id': categoryId,
        'name': name,
        'color': color,
        'icon': icon,
        'total_amount': totalAmount,
        'percentage': percentage,
      };
}

typedef CategoryTotalModel = CategoryAnalyticsModel;

class MerchantSpendingModel {
  const MerchantSpendingModel({
    required this.merchantName,
    required this.totalAmount,
    required this.transactionCount,
    required this.trendLabel,
  });

  final String merchantName;
  final int totalAmount;
  final int transactionCount;
  final String trendLabel;

  factory MerchantSpendingModel.fromJson(Map<String, dynamic> json) {
    return MerchantSpendingModel(
      merchantName: (json['merchant_name'] as String?) ?? 'Merchant',
      totalAmount: (json['total_amount'] as num?)?.toInt() ?? 0,
      transactionCount: (json['transaction_count'] as num?)?.toInt() ?? 0,
      trendLabel: (json['trend_label'] as String?) ?? 'Flat',
    );
  }

  Map<String, dynamic> toJson() => {
        'merchant_name': merchantName,
        'total_amount': totalAmount,
        'transaction_count': transactionCount,
        'trend_label': trendLabel,
      };
}

class EfficiencyScoreModel {
  const EfficiencyScoreModel({
    required this.score,
    required this.householdAverage,
    required this.actualSpending,
    required this.deltaPercentage,
    required this.insight,
  });

  final int score;
  final int householdAverage;
  final int actualSpending;
  final double deltaPercentage;
  final String insight;

  factory EfficiencyScoreModel.fromJson(Map<String, dynamic> json) {
    return EfficiencyScoreModel(
      score: (json['score'] as num?)?.toInt() ?? 0,
      householdAverage: (json['household_average'] as num?)?.toInt() ?? 0,
      actualSpending: (json['actual_spending'] as num?)?.toInt() ?? 0,
      deltaPercentage: (json['delta_percentage'] as num?)?.toDouble() ?? 0,
      insight: (json['insight'] as String?) ?? 'Efficiency data unavailable.',
    );
  }

  Map<String, dynamic> toJson() => {
        'score': score,
        'household_average': householdAverage,
        'actual_spending': actualSpending,
        'delta_percentage': deltaPercentage,
        'insight': insight,
      };
}
