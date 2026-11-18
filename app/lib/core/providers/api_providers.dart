import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/api_models.dart';

// ── Core service ───────────────────────────────────────────────────────────
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

// ── Dashboard ──────────────────────────────────────────────────────────────
final dashboardProvider = FutureProvider.autoDispose<DashboardResponse>((ref) {
  return ref.watch(apiServiceProvider).getDashboard();
});

// ── Transactions ───────────────────────────────────────────────────────────
// Parameters: (category filter, search query)
typedef TxParams = ({String category, String search});

final transactionsProvider =
    FutureProvider.autoDispose.family<TransactionListResponse, TxParams>(
  (ref, params) {
    return ref.watch(apiServiceProvider).getTransactions(
          category: params.category == 'all' ? null : params.category,
          search: params.search.isEmpty ? null : params.search,
          limit: 100,
        );
  },
);

// ── Forecast ───────────────────────────────────────────────────────────────
final forecastProvider = FutureProvider.autoDispose<ForecastResponse>((ref) {
  return ref.watch(apiServiceProvider).getForecast();
});

// ── Anomalies ──────────────────────────────────────────────────────────────
final anomaliesProvider =
    FutureProvider.autoDispose<List<AnomalyModel>>((ref) {
  return ref.watch(apiServiceProvider).getAnomalies(acknowledged: false);
});
