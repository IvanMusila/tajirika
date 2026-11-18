import 'package:dio/dio.dart';
import '../models/api_models.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  final Dio _dio;
  final String deviceToken;

  // ── Change this to your laptop's local IP ─────────────────────────────
  static const String baseUrl = 'http://192.168.100.16:8000';

  ApiService({this.deviceToken = 'demo-ivan'})
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 30),
        ),
      ) {
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        error: true,
        logPrint: (o) => debugPrint('[API] $o'),
      ),
    );
  }

  // ── Dashboard ──────────────────────────────────────────────────────────
  Future<DashboardResponse> getDashboard() async {
    final res = await _dio.get(
      '/dashboard',
      queryParameters: {'device_token': deviceToken},
    );
    return DashboardResponse.fromJson(res.data as Map<String, dynamic>);
  }

  // ── Transactions ───────────────────────────────────────────────────────
  Future<TransactionListResponse> getTransactions({
    int limit = 50,
    int offset = 0,
    String? category,
    String? search,
  }) async {
    final params = <String, dynamic>{
      'device_token': deviceToken,
      'limit': limit,
      'offset': offset,
    };
    if (category != null && category.toLowerCase() != 'all')
      params['category'] = category;
    if (search != null && search.isNotEmpty) params['search'] = search;
    final res = await _dio.get('/transactions', queryParameters: params);
    return TransactionListResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<TransactionModel> labelTransaction(String id, String category) async {
    final res = await _dio.patch(
      '/transactions/$id/label',
      data: {'device_token': deviceToken, 'category': category},
    );
    return TransactionModel.fromJson(res.data as Map<String, dynamic>);
  }

  // ── Forecast ───────────────────────────────────────────────────────────
  Future<ForecastResponse> getForecast() async {
    final res = await _dio.get(
      '/forecast',
      queryParameters: {'device_token': deviceToken},
    );
    return ForecastResponse.fromJson(res.data as Map<String, dynamic>);
  }

  // ── Anomalies ──────────────────────────────────────────────────────────
  Future<List<AnomalyModel>> getAnomalies({bool? acknowledged}) async {
    final params = <String, dynamic>{'device_token': deviceToken};
    if (acknowledged != null) params['acknowledged'] = acknowledged;
    final res = await _dio.get('/anomalies', queryParameters: params);
    return (res.data as List)
        .map((e) => AnomalyModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AnomalyModel> acknowledgeAnomaly(String id) async {
    final res = await _dio.patch(
      '/anomalies/$id',
      data: {'device_token': deviceToken},
    );
    return AnomalyModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> scanAnomalies() async {
    await _dio.post(
      '/anomalies/scan',
      queryParameters: {'device_token': deviceToken},
    );
  }

  Future<Map<String, dynamic>> syncTransactions(
    List<Map<String, dynamic>> transactions,
  ) async {
    final res = await _dio.post(
      '/transactions/sync',
      data: {'device_token': deviceToken, 'transactions': transactions},
    );
    return res.data as Map<String, dynamic>;
  }
}
