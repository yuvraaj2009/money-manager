import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/constants/api_constants.dart';
import '../models/analytics_model.dart';
import '../models/budget_model.dart';
import '../models/form_metadata_model.dart';
import '../models/profile_model.dart';
import '../models/transaction_model.dart';

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<TransactionModel>> getTransactions() async {
    final json = await getJson('/transactions');
    return _decodeList(json, TransactionModel.fromJson);
  }

  Future<List<TransactionModel>> getRecentTransactions({int limit = 5}) async {
    final json = await getJson(
      '/transactions/recent',
      queryParameters: {'limit': '$limit'},
    );
    return _decodeList(json, TransactionModel.fromJson);
  }

  Future<TransactionModel> getTransaction(String transactionId) async {
    final json = await getJson('/transactions/$transactionId');
    return TransactionModel.fromJson(_decodeMap(json));
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
    final json = await postJson('/transactions', {
      'amount': amount,
      'category_id': categoryId,
      'description': description,
      'payment_method': paymentMethod,
      'account_id': accountId,
      'date': date.toIso8601String().split('T').first,
      'receipt_url': receiptUrl,
    });
    return TransactionModel.fromJson(_decodeMap(json));
  }

  Future<TransactionFormMetadataModel> getTransactionFormMetadata() async {
    final json = await getJson('/transactions/form-metadata');
    return TransactionFormMetadataModel.fromJson(_decodeMap(json));
  }

  Future<MonthlySummaryModel> getMonthlySummary() async {
    final json = await getJson('/analytics/summary');
    return MonthlySummaryModel.fromJson(_decodeMap(json));
  }

  Future<YearSummaryModel> getYearlySummary() async {
    final json = await getJson('/summary/year');
    return YearSummaryModel.fromJson(_decodeMap(json));
  }

  Future<List<CategoryAnalyticsModel>> getCategoryAnalytics() async {
    final json = await getJson('/analytics/categories');
    return _decodeList(json, CategoryAnalyticsModel.fromJson);
  }

  Future<List<TrendPointModel>> getTrends() async {
    final json = await getJson('/analytics/trends');
    return _decodeList(json, TrendPointModel.fromJson);
  }

  Future<List<MerchantSpendingModel>> getTopMerchants() async {
    final json = await getJson('/analytics/top-merchants');
    return _decodeList(json, MerchantSpendingModel.fromJson);
  }

  Future<EfficiencyScoreModel> getEfficiency() async {
    final json = await getJson('/analytics/efficiency');
    return EfficiencyScoreModel.fromJson(_decodeMap(json));
  }

  Future<List<BudgetModel>> getBudgets() async {
    final json = await getJson('/budgets');
    return _decodeList(json, BudgetModel.fromJson);
  }

  Future<BudgetModel> createBudget({
    required String categoryId,
    required int monthlyLimit,
  }) async {
    final json = await postJson('/budgets', {
      'category_id': categoryId,
      'monthly_limit': monthlyLimit,
    });
    return BudgetModel.fromJson(_decodeMap(json));
  }

  Future<BudgetUtilizationModel> getBudgetUtilization() async {
    final json = await getJson('/analytics/budget-utilization');
    return BudgetUtilizationModel.fromJson(_decodeMap(json));
  }

  Future<ProfileModel> getProfile() async {
    final json = await getJson('/profile');
    return ProfileModel.fromJson(_decodeMap(json));
  }

  Future<ProfileModel> createProfile(ProfileModel profile) async {
    final json = await postJson('/profile', profile.toJson());
    return ProfileModel.fromJson(_decodeMap(json));
  }

  Future<ProfileModel> updateProfile(ProfileModel profile) async {
    final json = await putJson('/profile', profile.toJson());
    return ProfileModel.fromJson(_decodeMap(json));
  }

  Future<dynamic> getJson(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final uri = _buildUri(path, queryParameters: queryParameters);
    final response = await _runRequest(
      () => _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 12)),
      uri,
    );
    return _decode(response);
  }

  Future<dynamic> postJson(String path, Map<String, dynamic> body) async {
    final uri = _buildUri(path);
    final response = await _runRequest(
      () => _client
          .post(uri, headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 12)),
      uri,
    );
    return _decode(response);
  }

  Future<dynamic> putJson(String path, Map<String, dynamic> body) async {
    final uri = _buildUri(path);
    final response = await _runRequest(
      () => _client
          .put(uri, headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 12)),
      uri,
    );
    return _decode(response);
  }

  Future<http.Response> _runRequest(
    Future<http.Response> Function() request,
    Uri uri,
  ) async {
    try {
      return await request();
    } on TimeoutException {
      throw ApiException(
        statusCode: 408,
        message:
            'The Money Manager backend at $uri timed out. Check that FastAPI is running and your phone can reach the laptop on the same network.',
      );
    } on SocketException {
      throw ApiException(
        statusCode: 503,
        message:
            'Unable to reach the Money Manager backend at $uri. Verify the API base URL, keep the phone and laptop on the same network, and confirm FastAPI is running.',
      );
    } on http.ClientException catch (error) {
      throw ApiException(
        statusCode: 503,
        message: 'Network request failed for $uri: ${error.message}',
      );
    }
  }

  Uri _buildUri(String path, {Map<String, String>? queryParameters}) {
    final normalizedBase = ApiConstants.baseUrl.endsWith('/')
        ? ApiConstants.baseUrl.substring(0, ApiConstants.baseUrl.length - 1)
        : ApiConstants.baseUrl;
    return Uri.parse('$normalizedBase$path')
        .replace(queryParameters: queryParameters);
  }

  dynamic _decode(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return null;
      }
      try {
        return jsonDecode(response.body);
      } on FormatException {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'The backend returned an invalid JSON response.',
        );
      }
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: response.body.isEmpty ? 'Unexpected API error.' : response.body,
    );
  }

  Map<String, dynamic> _decodeMap(dynamic json) {
    return json as Map<String, dynamic>;
  }

  List<T> _decodeList<T>(
    dynamic json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final list = json as List<dynamic>;
    return list.map((item) => fromJson(item as Map<String, dynamic>)).toList();
  }

  Map<String, String> get _headers => const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
}

class ApiException implements Exception {
  ApiException({required this.statusCode, required this.message});

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
