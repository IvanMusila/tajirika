import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({super.key});

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  // What-if slider values (0.0 = no cut, 1.0 = 100% cut)
  double _foodCut = 0.0;
  double _transportCut = 0.0;
  double _entertainmentCut = 0.0;

  // Base values
  final int _baseRunway = 18;
  final int _currentBalance = 8432;
  final double _baseDailySpend = 468.4;

  // Monthly spend per category
  final Map<String, double> _categorySpend = {
    'Food': 4200,
    'Transport': 2800,
    'Entertainment': 1750,
  };

  int get _adjustedRunway {
    double savedPerMonth = (_categorySpend['Food']! * _foodCut) +
        (_categorySpend['Transport']! * _transportCut) +
        (_categorySpend['Entertainment']! * _entertainmentCut);
    double newDailySpend = _baseDailySpend - (savedPerMonth / 30);
    if (newDailySpend <= 0) return 999;
    return (_currentBalance / newDailySpend).floor();
  }

  double get _monthlySavings {
    return (_categorySpend['Food']! * _foodCut) +
        (_categorySpend['Transport']! * _transportCut) +
        (_categorySpend['Entertainment']! * _entertainmentCut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              Text('Forecast', style: AppTextStyles.headingLarge),
              const SizedBox(height: 4),
              Text(
                'See where your money is headed',
                style: AppTextStyles.bodyMedium,
              ),

              const SizedBox(height: 24),

              // Runway card
              _RunwayForecastCard(
                baseRunway: _baseRunway,
                adjustedRunway: _adjustedRunway,
                monthlySavings: _monthlySavings,
              ),

              const SizedBox(height: 20),

              // Upcoming bills
              Text('Upcoming bills', style: AppTextStyles.headingSmall),
              const SizedBox(height: 12),
              _UpcomingBills(),

              const SizedBox(height: 20),

              // Projection chart
              _ProjectionChart(),

              const SizedBox(height: 20),

              // What-if section
              Text('What if I spend less?',
                  style: AppTextStyles.headingSmall),
              const SizedBox(height: 4),
              Text(
                'Drag the sliders to see how cuts affect your runway',
                style: AppTextStyles.bodyMedium.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 16),

              _WhatIfCard(
                category: 'Food',
                icon: Icons.restaurant_menu_outlined,
                color: const Color(0xFF8BC4A0),
                monthlyAmount: _categorySpend['Food']!,
                value: _foodCut,
                onChanged: (v) => setState(() => _foodCut = v),
              ),

              const SizedBox(height: 10),

              _WhatIfCard(
                category: 'Transport',
                icon: Icons.directions_car_outlined,
                color: const Color(0xFF64B5F6),
                monthlyAmount: _categorySpend['Transport']!,
                value: _transportCut,
                onChanged: (v) => setState(() => _transportCut = v),
              ),

              const SizedBox(height: 10),

              _WhatIfCard(
                category: 'Entertainment',
                icon: Icons.movie_outlined,
                color: const Color(0xFFFF8A65),
                monthlyAmount: _categorySpend['Entertainment']!,
                value: _entertainmentCut,
                onChanged: (v) => setState(() => _entertainmentCut = v),
              ),

              const SizedBox(height: 20),

              // Seasonal warning
              _SeasonalWarning(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Runway Forecast Card
// ─────────────────────────────────────────────
class _RunwayForecastCard extends StatelessWidget {
  final int baseRunway;
  final int adjustedRunway;
  final double monthlySavings;

  const _RunwayForecastCard({
    required this.baseRunway,
    required this.adjustedRunway,
    required this.monthlySavings,
  });

  @override
  Widget build(BuildContext context) {
    final hasChanges = adjustedRunway != baseRunway;
    final extended = adjustedRunway - baseRunway;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasChanges ? 'Adjusted runway' : 'Current runway',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  '$adjustedRunway',
                  key: ValueKey(adjustedRunway),
                  style: AppTextStyles.displayLarge.copyWith(
                    fontSize: 56,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'days',
                  style: AppTextStyles.headingMedium
                      .copyWith(color: Colors.white70),
                ),
              ),
              const Spacer(),
              if (hasChanges)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '+$extended days',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          if (hasChanges) ...[
            const SizedBox(height: 16),
            Container(height: 1, color: Colors.white24),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.savings_outlined,
                    color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Text(
                  'You save Ksh ${monthlySavings.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} this month',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: Colors.white),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Upcoming Bills
// ─────────────────────────────────────────────
class _UpcomingBills extends StatelessWidget {
  final List<Map<String, dynamic>> _bills = const [
    {
      'label': 'Rent',
      'amount': 'Ksh 18,000',
      'dueIn': 13,
      'icon': Icons.home_outlined,
      'color': Color(0xFF8BC4A0),
      'urgent': false,
    },
    {
      'label': 'KCB Loan',
      'amount': 'Ksh 3,500',
      'dueIn': 27,
      'icon': Icons.account_balance_outlined,
      'color': Color(0xFF64B5F6),
      'urgent': false,
    },
    {
      'label': 'Netflix',
      'amount': 'Ksh 1,100',
      'dueIn': 3,
      'icon': Icons.play_circle_outline_rounded,
      'color': Color(0xFFFF8A65),
      'urgent': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: _bills.asMap().entries.map((entry) {
          final isLast = entry.key == _bills.length - 1;
          final bill = entry.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: (bill['color'] as Color).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        bill['icon'] as IconData,
                        color: bill['color'] as Color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bill['label'] as String,
                            style: AppTextStyles.headingSmall
                                .copyWith(fontSize: 14),
                          ),
                          Text(
                            'Due in ${bill['dueIn']} days',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: bill['urgent'] as bool
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                              fontWeight: bill['urgent'] as bool
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      bill['amount'] as String,
                      style: AppTextStyles.headingSmall.copyWith(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                const Divider(
                    height: 1,
                    color: AppColors.background,
                    indent: 70),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Projection Chart
// ─────────────────────────────────────────────
class _ProjectionChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('30-day projection', style: AppTextStyles.headingSmall),
          const SizedBox(height: 4),
          Text(
            'Solid = actual  •  Dashed = projected',
            style: AppTextStyles.labelSmall,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: AppColors.background,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 7,
                      getTitlesWidget: (value, meta) => Text(
                        'Day ${value.toInt()}',
                        style: AppTextStyles.labelSmall
                            .copyWith(fontSize: 10),
                      ),
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 30,
                minY: 0,
                maxY: 10000,
                lineBarsData: [
                  // Actual (solid)
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 8432),
                      FlSpot(3, 7100),
                      FlSpot(7, 5800),
                      FlSpot(10, 4900),
                      FlSpot(14, 3200),
                      FlSpot(17, 2100),
                      FlSpot(18, 1650),
                    ],
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withOpacity(0.08),
                    ),
                  ),
                  // Projected (dashed)
                  LineChartBarData(
                    spots: const [
                      FlSpot(18, 1650),
                      FlSpot(21, 900),
                      FlSpot(25, 200),
                      FlSpot(28, 0),
                    ],
                    isCurved: true,
                    color: AppColors.error.withOpacity(0.6),
                    barWidth: 2,
                    dashArray: [6, 4],
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// What-If Card
// ─────────────────────────────────────────────
class _WhatIfCard extends StatelessWidget {
  final String category;
  final IconData icon;
  final Color color;
  final double monthlyAmount;
  final double value;
  final ValueChanged<double> onChanged;

  const _WhatIfCard({
    required this.category,
    required this.icon,
    required this.color,
    required this.monthlyAmount,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final saving = (monthlyAmount * value).toInt();
    final percent = (value * 100).toInt();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category,
                        style: AppTextStyles.headingSmall
                            .copyWith(fontSize: 14)),
                    Text(
                      'Ksh ${monthlyAmount.toInt()}/month',
                      style: AppTextStyles.labelSmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    percent > 0 ? '-$percent%' : 'No cut',
                    style: AppTextStyles.headingSmall.copyWith(
                      fontSize: 14,
                      color: percent > 0
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                  ),
                  if (saving > 0)
                    Text(
                      'save Ksh $saving',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                ],
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: AppColors.background,
              thumbColor: color,
              overlayColor: color.withOpacity(0.15),
              trackHeight: 4,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: value,
              min: 0.0,
              max: 0.5,
              divisions: 10,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Seasonal Warning
// ─────────────────────────────────────────────
class _SeasonalWarning extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calendar_today_outlined,
              color: AppColors.primaryDark,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'December ahead',
                  style: AppTextStyles.headingSmall.copyWith(
                    fontSize: 14,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your spend typically rises 60% in December. That\'s 10 weeks away.',
                  style: AppTextStyles.bodyMedium.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}