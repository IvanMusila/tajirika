class CategoryTotal {
  final String category;
  final double total;
  final int count;
  final double percentage;

  const CategoryTotal({
    required this.category,
    required this.total,
    required this.count,
    required this.percentage,
  });

  factory CategoryTotal.fromJson(Map<String, dynamic> j) => CategoryTotal(
        category: j['category'] as String,
        total: (j['total'] as num).toDouble(),
        count: j['count'] as int,
        percentage: (j['percentage'] as num).toDouble(),
      );
}

class AnomalySummary {
  final String id;
  final String merchantName;
  final double amount;
  final String category;
  final String severity;
  final String description;
  final DateTime detectedAt;

  const AnomalySummary({
    required this.id,
    required this.merchantName,
    required this.amount,
    required this.category,
    required this.severity,
    required this.description,
    required this.detectedAt,
  });

  factory AnomalySummary.fromJson(Map<String, dynamic> j) => AnomalySummary(
        id: j['id'] as String,
        merchantName: j['merchant_name'] as String,
        amount: (j['amount'] as num).toDouble(),
        category: j['category'] as String,
        severity: j['severity'] as String,
        description: j['description'] as String,
        detectedAt: DateTime.parse(j['detected_at'] as String),
      );
}

class DashboardResponse {
  final int? runwayDays;
  final double currentBalance;
  final double dailyAvg;
  final double monthlyForecast;
  final String method;
  final List<CategoryTotal> categoryTotals;
  final List<AnomalySummary> recentAnomalies;
  final int totalTransactions;
  final double totalSpend30d;
  final DateTime? lastSynced;

  const DashboardResponse({
    required this.runwayDays,
    required this.currentBalance,
    required this.dailyAvg,
    required this.monthlyForecast,
    required this.method,
    required this.categoryTotals,
    required this.recentAnomalies,
    required this.totalTransactions,
    required this.totalSpend30d,
    required this.lastSynced,
  });

  factory DashboardResponse.fromJson(Map<String, dynamic> j) =>
      DashboardResponse(
        runwayDays: j['runway_days'] as int?,
        currentBalance: (j['current_balance'] as num).toDouble(),
        dailyAvg: (j['daily_avg'] as num).toDouble(),
        monthlyForecast: (j['monthly_forecast'] as num).toDouble(),
        method: j['method'] as String,
        categoryTotals: (j['category_totals'] as List)
            .map((e) => CategoryTotal.fromJson(e as Map<String, dynamic>))
            .toList(),
        recentAnomalies: (j['recent_anomalies'] as List)
            .map((e) => AnomalySummary.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalTransactions: j['total_transactions'] as int,
        totalSpend30d: (j['total_spend_30d'] as num).toDouble(),
        lastSynced: j['last_synced'] != null
            ? DateTime.parse(j['last_synced'] as String)
            : null,
      );
}

class TransactionModel {
  final String id;
  final String receiptNo;
  final DateTime timestamp;
  final String merchantName;
  final String merchantId;
  final String transactionType;
  final double amount;
  final double balanceAfter;
  final String category;
  final String labelSource;
  final double confidenceScore;
  final bool isDebit;

  const TransactionModel({
    required this.id,
    required this.receiptNo,
    required this.timestamp,
    required this.merchantName,
    required this.merchantId,
    required this.transactionType,
    required this.amount,
    required this.balanceAfter,
    required this.category,
    required this.labelSource,
    required this.confidenceScore,
    required this.isDebit,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> j) => TransactionModel(
        id: j['id'] as String,
        receiptNo: j['receipt_no'] as String,
        timestamp: DateTime.parse(j['timestamp'] as String),
        merchantName: j['merchant_name'] as String,
        merchantId: j['merchant_id'] as String,
        transactionType: j['transaction_type'] as String,
        amount: (j['amount'] as num).toDouble(),
        balanceAfter: (j['balance_after'] as num).toDouble(),
        category: j['category'] as String,
        labelSource: j['label_source'] as String,
        confidenceScore: (j['confidence_score'] as num).toDouble(),
        isDebit: j['is_debit'] as bool,
      );
}

class TransactionListResponse {
  final List<TransactionModel> transactions;
  final int total;

  const TransactionListResponse({
    required this.transactions,
    required this.total,
  });

  factory TransactionListResponse.fromJson(Map<String, dynamic> j) =>
      TransactionListResponse(
        transactions: (j['transactions'] as List)
            .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: j['total'] as int,
      );
}

class ForecastPoint {
  final String date;
  final double yhat;
  final double yhatLower;
  final double yhatUpper;

  const ForecastPoint({
    required this.date,
    required this.yhat,
    required this.yhatLower,
    required this.yhatUpper,
  });

  factory ForecastPoint.fromJson(Map<String, dynamic> j) => ForecastPoint(
        date: j['date'] as String,
        yhat: (j['yhat'] as num).toDouble(),
        yhatLower: (j['yhat_lower'] as num).toDouble(),
        yhatUpper: (j['yhat_upper'] as num).toDouble(),
      );
}

class ForecastResponse {
  final int? runwayDays;
  final double dailyAvgKsh;
  final double monthlyForecastKsh;
  final double largeMonthlyKsh;
  final String method;
  final List<ForecastPoint> forecastSeries;

  const ForecastResponse({
    required this.runwayDays,
    required this.dailyAvgKsh,
    required this.monthlyForecastKsh,
    required this.largeMonthlyKsh,
    required this.method,
    required this.forecastSeries,
  });

  factory ForecastResponse.fromJson(Map<String, dynamic> j) => ForecastResponse(
        runwayDays: j['runway_days'] as int?,
        dailyAvgKsh: (j['daily_avg_ksh'] as num).toDouble(),
        monthlyForecastKsh: (j['monthly_forecast_ksh'] as num).toDouble(),
        largeMonthlyKsh: (j['large_monthly_ksh'] as num).toDouble(),
        method: j['method'] as String,
        forecastSeries: (j['forecast_series'] as List)
            .map((e) => ForecastPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class AnomalyModel {
  final String id;
  final String alertType;
  final String receiptNo;
  final String merchantName;
  final String category;
  final double amount;
  final String severity;
  final double score;
  final String description;
  final bool acknowledged;
  final DateTime detectedAt;

  const AnomalyModel({
    required this.id,
    required this.alertType,
    required this.receiptNo,
    required this.merchantName,
    required this.category,
    required this.amount,
    required this.severity,
    required this.score,
    required this.description,
    required this.acknowledged,
    required this.detectedAt,
  });

  factory AnomalyModel.fromJson(Map<String, dynamic> j) => AnomalyModel(
        id: j['id'] as String,
        alertType: j['alert_type'] as String,
        receiptNo: j['receipt_no'] as String,
        merchantName: j['merchant_name'] as String,
        category: j['category'] as String,
        amount: (j['amount'] as num).toDouble(),
        severity: j['severity'] as String,
        score: (j['score'] as num).toDouble(),
        description: j['description'] as String,
        acknowledged: j['acknowledged'] as bool,
        detectedAt: DateTime.parse(j['detected_at'] as String),
      );
}
