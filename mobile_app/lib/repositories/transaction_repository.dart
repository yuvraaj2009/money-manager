import '../core/cache/cache_service.dart';
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
  final CacheService _cache = CacheService.instance;

  static const _keyDashboard = 'dashboard';
  static const _keyAnalytics = 'analytics';
  static const _keyBudget = 'budget';

  // ---------------------------------------------------------------------------
  // Cache-first loaders
  // ---------------------------------------------------------------------------

  /// Returns cached [DashboardBundle] if available, otherwise null.
  Future<DashboardBundle?> loadDashboardDataFromCache() async {
    try {
      final raw = await _cache.get(_keyDashboard);
      if (raw == null) return null;
      final map = raw as Map<String, dynamic>;
      return _decodeDashboardBundle(map);
    } catch (_) {
      return null;
    }
  }

  /// Fetches fresh data from the network, caches it, and returns it.
  Future<DashboardBundle> loadDashboardData() async {
    final results = await Future.wait<Object>([
      _analyticsService.getMonthlySummary(),
      _analyticsService.getYearlySummary(),
      _analyticsService.getEfficiency(),
      _analyticsService.getCategoryAnalytics(),
      _transactionService.getRecentTransactions(limit: 4),
      _budgetService.getBudgetUtilization(),
    ]);
    final bundle = DashboardBundle(
      summary: results[0] as MonthlySummaryModel,
      yearSummary: results[1] as YearSummaryModel,
      efficiency: results[2] as EfficiencyScoreModel,
      categories: results[3] as List<CategoryAnalyticsModel>,
      recentTransactions: results[4] as List<TransactionModel>,
      budgetUtilization: results[5] as BudgetUtilizationModel,
    );
    // Cache the raw JSON representation
    await _cache.put(_keyDashboard, _encodeDashboardBundle(bundle));
    return bundle;
  }

  /// Returns cached [AnalyticsBundle] if available, otherwise null.
  Future<AnalyticsBundle?> loadAnalyticsDataFromCache() async {
    try {
      final raw = await _cache.get(_keyAnalytics);
      if (raw == null) return null;
      final map = raw as Map<String, dynamic>;
      return _decodeAnalyticsBundle(map);
    } catch (_) {
      return null;
    }
  }

  Future<AnalyticsBundle> loadAnalyticsData() async {
    final results = await Future.wait<Object>([
      _analyticsService.getMonthlySummary(),
      _analyticsService.getEfficiency(),
      _analyticsService.getTrends(),
      _analyticsService.getCategoryAnalytics(),
      _analyticsService.getTopMerchants(),
    ]);
    final bundle = AnalyticsBundle(
      summary: results[0] as MonthlySummaryModel,
      efficiency: results[1] as EfficiencyScoreModel,
      trends: results[2] as List<TrendPointModel>,
      categories: results[3] as List<CategoryAnalyticsModel>,
      topMerchants: results[4] as List<MerchantSpendingModel>,
    );
    await _cache.put(_keyAnalytics, _encodeAnalyticsBundle(bundle));
    return bundle;
  }

  /// Returns cached [BudgetBundle] if available, otherwise null.
  Future<BudgetBundle?> loadBudgetDataFromCache() async {
    try {
      final raw = await _cache.get(_keyBudget);
      if (raw == null) return null;
      final map = raw as Map<String, dynamic>;
      return _decodeBudgetBundle(map);
    } catch (_) {
      return null;
    }
  }

  Future<BudgetBundle> loadBudgetData() async {
    final results = await Future.wait<Object>([
      _analyticsService.getMonthlySummary(),
      _budgetService.getBudgets(),
      _budgetService.getBudgetUtilization(),
      _transactionService.getFormMetadata(),
    ]);
    final bundle = BudgetBundle(
      summary: results[0] as MonthlySummaryModel,
      budgets: results[1] as List<BudgetModel>,
      utilization: results[2] as BudgetUtilizationModel,
      metadata: results[3] as TransactionFormMetadataModel,
    );
    await _cache.put(_keyBudget, _encodeBudgetBundle(bundle));
    return bundle;
  }

  /// Invalidate all caches (call after mutations like creating transactions).
  Future<void> invalidateCache() async {
    await Future.wait([
      _cache.remove(_keyDashboard),
      _cache.remove(_keyAnalytics),
      _cache.remove(_keyBudget),
    ]);
  }

  // ---------------------------------------------------------------------------
  // Non-cached operations
  // ---------------------------------------------------------------------------

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
  }) async {
    final result = await _transactionService.createTransaction(
      amount: amount,
      categoryId: categoryId,
      description: description,
      paymentMethod: paymentMethod,
      accountId: accountId,
      date: date,
      receiptUrl: receiptUrl,
    );
    await invalidateCache();
    return result;
  }

  Future<BudgetModel> saveBudget({
    required String categoryId,
    required int monthlyLimit,
  }) async {
    final result = await _budgetService.createBudget(
      categoryId: categoryId,
      monthlyLimit: monthlyLimit,
    );
    await invalidateCache();
    return result;
  }

  // ---------------------------------------------------------------------------
  // JSON encode/decode helpers for cache
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _encodeDashboardBundle(DashboardBundle b) => {
        'summary': b.summary.toJson(),
        'yearSummary': b.yearSummary.toJson(),
        'efficiency': b.efficiency.toJson(),
        'categories': b.categories.map((c) => c.toJson()).toList(),
        'recentTransactions': b.recentTransactions.map((t) => t.toJson()).toList(),
        'budgetUtilization': b.budgetUtilization.toJson(),
      };

  DashboardBundle _decodeDashboardBundle(Map<String, dynamic> m) => DashboardBundle(
        summary: MonthlySummaryModel.fromJson(m['summary'] as Map<String, dynamic>),
        yearSummary: YearSummaryModel.fromJson(m['yearSummary'] as Map<String, dynamic>),
        efficiency: EfficiencyScoreModel.fromJson(m['efficiency'] as Map<String, dynamic>),
        categories: (m['categories'] as List)
            .map((c) => CategoryAnalyticsModel.fromJson(c as Map<String, dynamic>))
            .toList(),
        recentTransactions: (m['recentTransactions'] as List)
            .map((t) => TransactionModel.fromJson(t as Map<String, dynamic>))
            .toList(),
        budgetUtilization:
            BudgetUtilizationModel.fromJson(m['budgetUtilization'] as Map<String, dynamic>),
      );

  Map<String, dynamic> _encodeAnalyticsBundle(AnalyticsBundle b) => {
        'summary': b.summary.toJson(),
        'efficiency': b.efficiency.toJson(),
        'trends': b.trends.map((t) => t.toJson()).toList(),
        'categories': b.categories.map((c) => c.toJson()).toList(),
        'topMerchants': b.topMerchants.map((m) => m.toJson()).toList(),
      };

  AnalyticsBundle _decodeAnalyticsBundle(Map<String, dynamic> m) => AnalyticsBundle(
        summary: MonthlySummaryModel.fromJson(m['summary'] as Map<String, dynamic>),
        efficiency: EfficiencyScoreModel.fromJson(m['efficiency'] as Map<String, dynamic>),
        trends: (m['trends'] as List)
            .map((t) => TrendPointModel.fromJson(t as Map<String, dynamic>))
            .toList(),
        categories: (m['categories'] as List)
            .map((c) => CategoryAnalyticsModel.fromJson(c as Map<String, dynamic>))
            .toList(),
        topMerchants: (m['topMerchants'] as List)
            .map((m) => MerchantSpendingModel.fromJson(m as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> _encodeBudgetBundle(BudgetBundle b) => {
        'summary': b.summary.toJson(),
        'budgets': b.budgets.map((b) => b.toJson()).toList(),
        'utilization': b.utilization.toJson(),
        'metadata': b.metadata.toJson(),
      };

  BudgetBundle _decodeBudgetBundle(Map<String, dynamic> m) => BudgetBundle(
        summary: MonthlySummaryModel.fromJson(m['summary'] as Map<String, dynamic>),
        budgets: (m['budgets'] as List)
            .map((b) => BudgetModel.fromJson(b as Map<String, dynamic>))
            .toList(),
        utilization:
            BudgetUtilizationModel.fromJson(m['utilization'] as Map<String, dynamic>),
        metadata:
            TransactionFormMetadataModel.fromJson(m['metadata'] as Map<String, dynamic>),
      );
}
