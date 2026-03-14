import '../models/form_metadata_model.dart';
import '../models/transaction_model.dart';
import 'api_service.dart';
import 'service_exception.dart';

class TransactionService {
  TransactionService(this._apiService);

  final ApiService _apiService;

  Future<List<TransactionModel>> getTransactions() {
    return _runSafely(
      _apiService.getTransactions,
      fallbackMessage: 'Unable to load transactions right now.',
    );
  }

  Future<List<TransactionModel>> getRecentTransactions({int limit = 5}) {
    return _runSafely(
      () => _apiService.getRecentTransactions(limit: limit),
      fallbackMessage: 'Unable to load recent transactions right now.',
    );
  }

  Future<TransactionModel> getTransactionDetail(String transactionId) {
    return _runSafely(
      () => _apiService.getTransaction(transactionId),
      fallbackMessage: 'Unable to load this transaction right now.',
    );
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
    return _runSafely(
      () => _apiService.createTransaction(
        amount: amount,
        categoryId: categoryId,
        description: description,
        paymentMethod: paymentMethod,
        accountId: accountId,
        date: date,
        receiptUrl: receiptUrl,
      ),
      fallbackMessage: 'Unable to save the transaction right now.',
    );
  }

  Future<TransactionFormMetadataModel> getFormMetadata() {
    return _runSafely(
      _apiService.getTransactionFormMetadata,
      fallbackMessage: 'Unable to load the transaction form right now.',
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
