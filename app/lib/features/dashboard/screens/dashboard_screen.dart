import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 100), // clears the pill
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Header
              _Header(),

              const SizedBox(height: 24),

              // Runway card
              _RunwayCard(),

              const SizedBox(height: 20),

              // Spend overview card
              _SpendOverviewCard(),

              const SizedBox(height: 20),

              // Categories
              const _SectionHeader(title: 'Spending breakdown'),
              const SizedBox(height: 12),
              _CategoriesSection(),

              const SizedBox(height: 20),

              // Anomaly alert
              _AnomalyAlert(),

              const SizedBox(height: 20),

              // Recent transactions
              const _SectionHeader(
                title: 'Recent transactions',
                actionLabel: 'See all',
              ),
              const SizedBox(height: 12),
              _RecentTransactions(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────
class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.person_outline_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back',
              style: AppTextStyles.labelSmall,
            ),
            Text(
              'Ivan',
              style: AppTextStyles.headingSmall,
            ),
          ],
        ),
        const Spacer(),
        // Notification bell
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: AppColors.textPrimary,
            size: 22,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Runway Card
// ─────────────────────────────────────────────
class _RunwayCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              const Icon(
                Icons.timelapse_rounded,
                color: Colors.white70,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Your money lasts',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '18',
                style: AppTextStyles.displayLarge.copyWith(
                  fontSize: 56,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'days',
                  style: AppTextStyles.headingMedium.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: Colors.white24,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const _RunwayStatItem(
                label: 'Balance',
                value: 'Ksh 8,432',
              ),
              Container(
                width: 1,
                height: 32,
                color: Colors.white24,
                margin: const EdgeInsets.symmetric(horizontal: 20),
              ),
              const _RunwayStatItem(
                label: 'Monthly spend',
                value: 'Ksh 22,000',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RunwayStatItem extends StatelessWidget {
  final String label;
  final String value;

  const _RunwayStatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(color: Colors.white60),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.headingSmall.copyWith(color: Colors.white),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Spend Overview Card (Chart)
// ─────────────────────────────────────────────
class _SpendOverviewCard extends StatelessWidget {
  final List<double> _weeklySpend = const [
    800, 600, 1200, 400, 2100, 1800, 500
  ];
  final List<String> _days = const [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];

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
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('This week', style: AppTextStyles.headingSmall),
              const Spacer(),
              Text(
                'Ksh 7,400 total',
                style: AppTextStyles.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 120,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 2500,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _days[value.toInt()],
                            style: AppTextStyles.labelSmall.copyWith(
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: _weeklySpend.asMap().entries.map((entry) {
                  final isFriday = entry.key == 4;
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value,
                        color: isFriday
                            ? AppColors.primary
                            : AppColors.primaryLight,
                        width: 20,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;

  const _SectionHeader({required this.title, this.actionLabel});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: AppTextStyles.headingSmall),
        const Spacer(),
        if (actionLabel != null)
          Text(
            actionLabel!,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Categories Section
// ─────────────────────────────────────────────
class _CategoriesSection extends StatelessWidget {
  final List<Map<String, dynamic>> _categories = const [
    {
      'icon': Icons.restaurant_menu_outlined,
      'label': 'Food',
      'amount': 'Ksh 4,200',
      'percent': 0.29,
      'color': Color(0xFF8BC4A0),
    },
    {
      'icon': Icons.directions_car_outlined,
      'label': 'Transport',
      'amount': 'Ksh 2,800',
      'percent': 0.19,
      'color': Color(0xFF8BC4A0),
    },
    {
      'icon': Icons.people_outline_rounded,
      'label': 'Family',
      'amount': 'Ksh 3,000',
      'percent': 0.21,
      'color': Color(0xFF8BC4A0),
    },
  ];

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
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: _categories.map((cat) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _CategoryRow(category: cat),
          );
        }).toList(),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final Map<String, dynamic> category;
  const _CategoryRow({required this.category});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (category['color'] as Color).withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            category['icon'] as IconData,
            color: category['color'] as Color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    category['label'] as String,
                    style: AppTextStyles.headingSmall.copyWith(fontSize: 14),
                  ),
                  const Spacer(),
                  Text(
                    category['amount'] as String,
                    style: AppTextStyles.headingSmall.copyWith(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: category['percent'] as double,
                  backgroundColor: AppColors.background,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    category['color'] as Color,
                  ),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Anomaly Alert
// ─────────────────────────────────────────────
class _AnomalyAlert extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.warning.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warning,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Spending spike detected',
                  style: AppTextStyles.headingSmall.copyWith(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Entertainment spend up 340% this week',
                  style: AppTextStyles.bodyMedium.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Recent Transactions
// ─────────────────────────────────────────────
class _RecentTransactions extends StatelessWidget {
  final List<Map<String, dynamic>> _transactions = const [
    {
      'merchant': 'Naivas Supermarket',
      'category': 'Groceries',
      'amount': '- Ksh 1,200',
      'time': 'Today, 6:45 PM',
      'icon': Icons.shopping_cart_outlined,
      'color': Color(0xFF8BC4A0),
      'isDebit': true,
    },
    {
      'merchant': 'Airtime Top-up',
      'category': 'Utilities',
      'amount': '- Ksh 50',
      'time': 'Today, 8:12 AM',
      'icon': Icons.phone_android_outlined,
      'color': Color(0xFF8BC4A0),
      'isDebit': true,
    },
    {
      'merchant': 'John Kamau',
      'category': 'Family Support',
      'amount': '- Ksh 2,500',
      'time': 'Yesterday',
      'icon': Icons.person_outline_rounded,
      'color': Color(0xFF8BC4A0),
      'isDebit': true,
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
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: _transactions.asMap().entries.map((entry) {
          final isLast = entry.key == _transactions.length - 1;
          return Column(
            children: [
              _TransactionRow(transaction: entry.value),
              if (!isLast)
                const Divider(
                  height: 1,
                  color: AppColors.background,
                  indent: 68,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final Map<String, dynamic> transaction;
  const _TransactionRow({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (transaction['color'] as Color).withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              transaction['icon'] as IconData,
              color: transaction['color'] as Color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction['merchant'] as String,
                  style: AppTextStyles.headingSmall.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  '${transaction['category']}  •  ${transaction['time']}',
                  style: AppTextStyles.labelSmall,
                ),
              ],
            ),
          ),
          Text(
            transaction['amount'] as String,
            style: AppTextStyles.headingSmall.copyWith(
              fontSize: 14,
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}