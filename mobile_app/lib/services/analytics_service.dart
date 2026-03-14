import '../models/analytics_model.dart';
import 'api_service.dart';
import 'service_exception.dart';

class AnalyticsService {
  AnalyticsService(this._apiService);

  final ApiService _apiService;

  Future<MonthlySummaryModel> getMonthlySummary() {
    return _runSafely(
      _apiService.getMonthlySummary,
      fallbackMessage: 'Unable to load the monthly summary right now.',
    );
  }

  Future<YearSummaryModel> getYearlySummary() {
    return _runSafely(
      _apiService.getYearlySummary,
      fallbackMessage: 'Unable to load yearly analytics right now.',
    );
  }

  Future<List<CategoryAnalyticsModel>> getCategoryAnalytics() {
    return _runSafely(
      _apiService.getCategoryAnalytics,
      fallbackMessage: 'Unable to load category analytics right now.',
    );
  }

  Future<List<TrendPointModel>> getTrends() {
    return _runSafely(
      _apiService.getTrends,
      fallbackMessage: 'Unable to load spending trends right now.',
    );
  }

  Future<List<MerchantSpendingModel>> getTopMerchants() {
    return _runSafely(
      _apiService.getTopMerchants,
      fallbackMessage: 'Unable to load top merchants right now.',
    );
  }

  Future<EfficiencyScoreModel> getEfficiency() {
    return _runSafely(
      _apiService.getEfficiency,
      fallbackMessage: 'Unable to load the efficiency score right now.',
    );
  }

  Future<T> _runSafely<T>(
    Future<T> Function() operation, {
    required String fallbackMessage,
  }) async {
    try {
      return await operation();
    } on ApiException catch (error) {
      throw ServiceException(error.message);
    } catch (_) {
      throw ServiceException(fallbackMessage);
    }
  }
}
