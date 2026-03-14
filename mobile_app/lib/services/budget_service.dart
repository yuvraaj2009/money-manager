import '../models/budget_model.dart';
import 'api_service.dart';
import 'service_exception.dart';

class BudgetService {
  BudgetService(this._apiService);

  final ApiService _apiService;

  Future<List<BudgetModel>> getBudgets() {
    return _runSafely(
      _apiService.getBudgets,
      fallbackMessage: 'Unable to load budgets right now.',
    );
  }

  Future<BudgetModel> createBudget({
    required String categoryId,
    required int monthlyLimit,
  }) {
    return _runSafely(
      () => _apiService.createBudget(
        categoryId: categoryId,
        monthlyLimit: monthlyLimit,
      ),
      fallbackMessage: 'Unable to save the budget right now.',
    );
  }

  Future<BudgetUtilizationModel> getBudgetUtilization() {
    return _runSafely(
      _apiService.getBudgetUtilization,
      fallbackMessage: 'Unable to load budget utilization right now.',
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
