import '../models/analytics_model.dart';
import '../models/budget_model.dart';
import '../models/form_metadata_model.dart';
import '../models/transaction_model.dart';
import '../services/analytics_service.dart';
import '../services/budget_service.dart';
import '../services/transaction_service.dart';

class DashboardBundle {
  const DashboardBundle({
    required this.summary,
    required this.yearSummary,
    required this.efficiency,
    required this.categories,
    required this.recentTransactions,
    required this.budgetUtilization,
  });

  final MonthlySummaryModel summary;
  final YearSummaryModel yearSummary;
  final EfficiencyScoreModel efficiency;
  final List<CategoryAnalyticsModel> categories;
  final List<TransactionModel> recentTransactions;
  final BudgetUtilizationModel budgetUtilization;
}

class AnalyticsBundle {
  const AnalyticsBundle({
    required this.summary,
    required this.efficiency,
    required this.trends,
    required this.categories,
    required this.topMerchants,
  });

  final MonthlySummaryModel summary;
  final EfficiencyScoreModel efficiency;
  final List<TrendPointModel> trends;
  final List<CategoryAnalyticsModel> categories;
  final List<MerchantSpendingModel> topMerchants;
}

class BudgetBundle {
  const BudgetBundle({
    required this.summary,
    required this.budgets,
    required this.utilization,
    required this.metadata,
  });

  final MonthlySummaryModel summary;
  final List<BudgetModel> budgets;
  final BudgetUtilizationModel utilization;
  final TransactionFormMetadataModel metadata;
}

class TransactionRepository {
  TransactionRepository({
    required TransactionService transactionService,
    required AnalyticsService analyticsService,
    required BudgetService budgetService,
  })  : _transactionService = transactionService,
        _analyticsService = analyticsService,
        _budgetService = budgetService;

  final TransactionService _transactionService;
  final AnalyticsService _analyticsService;
  final BudgetService _budgetService;

  Future<DashboardBundle> loadDashboardData() async {
    final results = await Future.wait<Object>([
      _analyticsService.getMonthlySummary(),
      _analyticsService.getYearlySummary(),
      _analyticsService.getEfficiency(),
      _analyticsService.getCategoryAnalytics(),
      _transactionService.getRecentTransactions(limit: 4),
      _budgetService.getBudgetUtilization(),
    ]);
    return DashboardBundle(
      summary: results[0] as MonthlySummaryModel,
      yearSummary: results[1] as YearSummaryModel,
      efficiency: results[2] as EfficiencyScoreModel,
      categories: results[3] as List<CategoryAnalyticsModel>,
      recentTransactions: results[4] as List<TransactionModel>,
      budgetUtilization: results[5] as BudgetUtilizationModel,
    );
  }

  Future<AnalyticsBundle> loadAnalyticsData() async {
    final results = await Future.wait<Object>([
      _analyticsService.getMonthlySummary(),
      _analyticsService.getEfficiency(),
      _analyticsService.getTrends(),
      _analyticsService.getCategoryAnalytics(),
      _analyticsService.getTopMerchants(),
    ]);
    return AnalyticsBundle(
      summary: results[0] as MonthlySummaryModel,
      efficiency: results[1] as EfficiencyScoreModel,
      trends: results[2] as List<TrendPointModel>,
      categories: results[3] as List<CategoryAnalyticsModel>,
      topMerchants: results[4] as List<MerchantSpendingModel>,
    );
  }

  Future<BudgetBundle> loadBudgetData() async {
    final results = await Future.wait<Object>([
      _analyticsService.getMonthlySummary(),
      _budgetService.getBudgets(),
      _budgetService.getBudgetUtilization(),
      _transactionService.getFormMetadata(),
    ]);
    return BudgetBundle(
      summary: results[0] as MonthlySummaryModel,
      budgets: results[1] as List<BudgetModel>,
      utilization: results[2] as BudgetUtilizationModel,
      metadata: results[3] as TransactionFormMetadataModel,
    );
  }

  Future<List<TransactionModel>> fetchTransactions() => _transactionService.getTransactions();

  Future<TransactionModel> fetchTransactionDetail(String transactionId) {
    return _transactionService.getTransactionDetail(transactionId);
  }

  Future<TransactionFormMetadataModel> fetchFormMetadata() {
    return _transactionService.getFormMetadata();
  }

  Future<TransactionModel> createTransaction({
    required int amount,
    required String categoryId,
    required String description,
    required String paymentMethod,
    required String accountId,
    required DateTime date,
    String? receiptUrl,
  }) {
    return _transactionService.createTransaction(
      amount: amount,
      categoryId: categoryId,
      description: description,
      paymentMethod: paymentMethod,
      accountId: accountId,
      date: date,
      receiptUrl: receiptUrl,
    );
  }

  Future<BudgetModel> saveBudget({
    required String categoryId,
    required int monthlyLimit,
  }) {
    return _budgetService.createBudget(categoryId: categoryId, monthlyLimit: monthlyLimit);
  }
}
