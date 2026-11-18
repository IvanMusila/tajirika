import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/models/api_models.dart';
import '../../../core/utils/category_utils.dart';

const _kActionableCategories = [
  'necessity', 'convenience', 'social', 'aspirational',
];

class ForecastScreen extends ConsumerStatefulWidget {
  const ForecastScreen({super.key});
  @override
  ConsumerState<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends ConsumerState<ForecastScreen> {
  final Map<String, double> _reductions = {
    'necessity': 0.0, 'convenience': 0.0,
    'social': 0.0, 'aspirational': 0.0,
  };

  bool get _hasAnyReduction => _reductions.values.any((v) => v > 0);

  // FIX: slider value is already a fraction 0.0–0.5, do NOT divide by 100
  int _computeNewRunway({
    required double balance,
    required double dailyAvg,
    required double largeMonthlyKsh,
    required List<CategoryTotal> categories,
  }) {
    final totalSpend = categories.fold(0.0, (s, c) => s + c.total);
    if (totalSpend <= 0 || dailyAvg <= 0) return 0;
    double totalReductionFraction = 0;
    for (final entry in _reductions.entries) {
      if (entry.value == 0) continue;
      try {
        final cat = categories.firstWhere((c) => c.category == entry.key);
        final share = cat.total / totalSpend;
        // entry.value is 0.0–0.5 (a fraction already, NOT a percentage)
        totalReductionFraction += share * entry.value;
      } catch (_) {}
    }
    // Higher reduction → lower adjustedDaily → higher runway
    final adjustedDaily = dailyAvg * (1 - totalReductionFraction);
    final dailyLarge = largeMonthlyKsh / 30;
    final totalDaily = adjustedDaily + dailyLarge;
    return totalDaily > 0 ? (balance / totalDaily).floor() : 999;
  }

  // FIX: use cat.total * entry.value so this matches each card's displayed saving
  double _computeTotalSavings(List<CategoryTotal> categories) {
    double saved = 0;
    for (final entry in _reductions.entries) {
      if (entry.value == 0) continue;
      try {
        final cat = categories.firstWhere((c) => c.category == entry.key);
        saved += cat.total * entry.value;
      } catch (_) {}
    }
    return saved;
  }

  @override
  Widget build(BuildContext context) {
    final fcAsync   = ref.watch(forecastProvider);
    final dashAsync = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: fcAsync.when(
          loading: () => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 16),
                Text('Building your forecast…',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                SizedBox(height: 4),
                Text('This takes a moment the first time.',
                    style: TextStyle(color: AppColors.textHint, fontSize: 12)),
              ],
            ),
          ),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textHint),
                const SizedBox(height: 12),
                Text('Could not load forecast', style: AppTextStyles.headingSmall),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => ref.refresh(forecastProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (fc) {
            final dash       = dashAsync.valueOrNull;
            final balance    = dash?.currentBalance ?? 0.0;
            final categories = dash?.categoryTotals ?? [];
            final baseRunway = fc.runwayDays ?? 0;
            final adjustedRunway = _hasAnyReduction
                ? _computeNewRunway(
                    balance: balance,
                    dailyAvg: fc.dailyAvgKsh,
                    largeMonthlyKsh: fc.largeMonthlyKsh,
                    categories: categories,
                  )
                : baseRunway;
            final totalSavings = _computeTotalSavings(categories);

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => ref.refresh(forecastProvider),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Text('Forecast', style: AppTextStyles.headingLarge),
                    const SizedBox(height: 4),
                    Text('See where your money is headed', style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 24),
                    _RunwayForecastCard(
                      baseRunway: baseRunway,
                      adjustedRunway: adjustedRunway,
                      monthlySavings: totalSavings,
                    ),
                    const SizedBox(height: 20),
                    _ProjectionChart(fc: fc, balance: balance),
                    const SizedBox(height: 20),
                    Text('What if I spend less?', style: AppTextStyles.headingSmall),
                    const SizedBox(height: 4),
                    Text('Drag a slider — the runway above updates live',
                        style: AppTextStyles.bodyMedium.copyWith(fontSize: 12)),
                    const SizedBox(height: 16),
                    ..._kActionableCategories
                        .where((cat) => categories.any((c) => c.category == cat && c.total > 0))
                        .map((cat) {
                      final catData = categories.firstWhere((c) => c.category == cat);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _WhatIfCard(
                          category: cat,
                          monthlyAmount: catData.total,
                          value: _reductions[cat] ?? 0.0,
                          onChanged: (v) => setState(() => _reductions[cat] = v),
                        ),
                      );
                    }),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RunwayForecastCard extends StatelessWidget {
  final int baseRunway;
  final int adjustedRunway;
  final double monthlySavings;
  const _RunwayForecastCard({
    required this.baseRunway, required this.adjustedRunway, required this.monthlySavings,
  });

  @override
  Widget build(BuildContext context) {
    final hasChanges = adjustedRunway != baseRunway;
    final extended   = adjustedRunway - baseRunway;
    final urgency    = adjustedRunway <= 3 ? AppColors.error
        : adjustedRunway <= 7 ? AppColors.warning : AppColors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: urgency,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(
          color: urgency.withValues(alpha: 0.35),
          blurRadius: 24, offset: const Offset(0, 8),
        )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(hasChanges ? 'Adjusted runway' : 'Current runway',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Text('$adjustedRunway',
                    key: ValueKey(adjustedRunway),
                    style: AppTextStyles.displayLarge.copyWith(fontSize: 56, color: Colors.white)),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text('days',
                    style: AppTextStyles.headingMedium.copyWith(color: Colors.white70)),
              ),
              const Spacer(),
              if (hasChanges && extended > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('+$extended days',
                      style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          if (hasChanges) ...[
            const SizedBox(height: 6),
            Text('Without cuts: $baseRunway days',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white60, fontSize: 12)),
          ],
          if (monthlySavings > 0) ...[
            const SizedBox(height: 16),
            Container(height: 1, color: Colors.white24),
            const SizedBox(height: 16),
            Row(children: [
              const Icon(Icons.savings_outlined, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text('Save ${CategoryUtils.formatAmount(monthlySavings)} / month',
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
            ]),
          ],
        ],
      ),
    );
  }
}

class _ProjectionChart extends StatelessWidget {
  final ForecastResponse fc;
  final double balance;
  const _ProjectionChart({required this.fc, required this.balance});

  List<FlSpot> _buildTrajectory() {
    if (fc.forecastSeries.isEmpty || balance <= 0) return [];
    final spots = <FlSpot>[FlSpot(0, balance)];
    double running = balance;
    final dailyLarge = fc.largeMonthlyKsh / 30;
    for (int i = 0; i < fc.forecastSeries.length; i++) {
      running -= (fc.forecastSeries[i].yhat + dailyLarge);
      running = running.clamp(0.0, double.infinity);
      spots.add(FlSpot((i + 1).toDouble(), running));
      if (running <= 0) break;
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final spots = _buildTrajectory();
    final maxY  = balance > 0 ? balance * 1.1 : 10000.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('30-day balance projection', style: AppTextStyles.headingSmall),
              const Spacer(),
              if (fc.runwayDays != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Runs out day ${fc.runwayDays}',
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.error)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Powered by Prophet ML model', style: AppTextStyles.labelSmall),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: spots.isEmpty
                ? Center(child: Text('Not enough data yet', style: AppTextStyles.bodyMedium))
                : LineChart(LineChartData(
                    gridData: FlGridData(
                      show: true, drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) =>
                          const FlLine(color: AppColors.background, strokeWidth: 1),
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(sideTitles: SideTitles(
                        showTitles: true, interval: 7,
                        getTitlesWidget: (v, _) => Text('Day ${v.toInt()}',
                            style: AppTextStyles.labelSmall.copyWith(fontSize: 10)),
                      )),
                      leftTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0, maxX: 30, minY: 0, maxY: maxY,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: AppColors.primary,
                        barWidth: 2.5,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.primary.withValues(alpha: 0.08),
                        ),
                      ),
                    ],
                  )),
          ),
        ],
      ),
    );
  }
}

class _WhatIfCard extends StatelessWidget {
  final String category;
  final double monthlyAmount;
  final double value;      // 0.0–0.5 fraction
  final ValueChanged<double> onChanged;
  const _WhatIfCard({
    required this.category, required this.monthlyAmount,
    required this.value, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color   = CategoryUtils.color(category);
    final percent = (value * 100).round();
    // saving = this category's monthly spend × reduction fraction
    // This is what gets summed in _computeTotalSavings()
    final saving  = (monthlyAmount * value).toInt();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(CategoryUtils.icon(category), color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(CategoryUtils.label(category),
                        style: AppTextStyles.headingSmall.copyWith(fontSize: 14)),
                    Text('${CategoryUtils.formatAmount(monthlyAmount)}/month',
                        style: AppTextStyles.labelSmall),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    percent > 0 ? 'Cut $percent%' : 'No cut',
                    style: AppTextStyles.headingSmall.copyWith(
                      fontSize: 13,
                      color: percent > 0 ? AppColors.success : AppColors.textSecondary,
                    ),
                  ),
                  if (saving > 0)
                    Text('save ${CategoryUtils.formatAmount(saving.toDouble())}',
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.success)),
                ],
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color, inactiveTrackColor: AppColors.background,
              thumbColor: color, overlayColor: color.withValues(alpha: 0.15),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: value, min: 0.0, max: 0.5, divisions: 10,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}