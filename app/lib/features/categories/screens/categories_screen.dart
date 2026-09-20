import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  int _touchedIndex = -1;
  String _selectedPeriod = 'This month';
  final List<String> _periods = ['This month', 'Last month', '3 months'];

  final List<Map<String, dynamic>> _categories = [
    {
      'label': 'Food & Drink',
      'amount': 4200,
      'percent': 0.29,
      'icon': Icons.restaurant_menu_outlined,
      'color': const Color(0xFF8BC4A0),
      'transactions': 23,
      'trend': '+12%',
      'trendUp': true,
    },
    {
      'label': 'Family Support',
      'amount': 3000,
      'percent': 0.21,
      'icon': Icons.people_outline_rounded,
      'color': const Color(0xFFFFB74D),
      'transactions': 4,
      'trend': '0%',
      'trendUp': null,
    },
    {
      'label': 'Transport',
      'amount': 2800,
      'percent': 0.19,
      'icon': Icons.directions_car_outlined,
      'color': const Color(0xFF64B5F6),
      'transactions': 31,
      'trend': '-5%',
      'trendUp': false,
    },
    {
      'label': 'Utilities',
      'amount': 1500,
      'percent': 0.10,
      'icon': Icons.bolt_outlined,
      'color': const Color(0xFFBA68C8),
      'transactions': 6,
      'trend': '+2%',
      'trendUp': true,
    },
    {
      'label': 'Entertainment',
      'amount': 1750,
      'percent': 0.12,
      'icon': Icons.movie_outlined,
      'color': const Color(0xFFFF8A65),
      'transactions': 8,
      'trend': '+340%',
      'trendUp': true,
    },
    {
      'label': 'Invisible Spend',
      'amount': 340,
      'percent': 0.02,
      'icon': Icons.visibility_off_outlined,
      'color': const Color(0xFF9E9E9E),
      'transactions': 47,
      'trend': '+1%',
      'trendUp': true,
    },
  ];

  int get _totalSpend =>
      _categories.fold(0, (sum, c) => sum + (c['amount'] as int));

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

              // Header
              Text('Categories', style: AppTextStyles.headingLarge),
              const SizedBox(height: 4),
              Text(
                'Ksh ${_totalSpend.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} total this month',
                style: AppTextStyles.bodyMedium,
              ),

              const SizedBox(height: 20),

              // Period selector
              Row(
                children: _periods.map((period) {
                  final isSelected = _selectedPeriod == period;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedPeriod = period),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        period,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Donut chart card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              pieTouchData: PieTouchData(
                                touchCallback: (event, response) {
                                  setState(() {
                                    if (!event
                                            .isInterestedForInteractions ||
                                        response == null ||
                                        response.touchedSection == null) {
                                      _touchedIndex = -1;
                                      return;
                                    }
                                    _touchedIndex = response
                                        .touchedSection!
                                        .touchedSectionIndex;
                                  });
                                },
                              ),
                              borderData: FlBorderData(show: false),
                              sectionsSpace: 3,
                              centerSpaceRadius: 64,
                              sections: _categories
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                final isTouched =
                                    entry.key == _touchedIndex;
                                return PieChartSectionData(
                                  color: entry.value['color'] as Color,
                                  value: (entry.value['percent'] as double) *
                                      100,
                                  title: '',
                                  radius: isTouched ? 36 : 28,
                                );
                              }).toList(),
                            ),
                          ),
                          // Center label
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _touchedIndex >= 0
                                    ? 'Ksh ${(_categories[_touchedIndex]['amount'] as int).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}'
                                    : 'Ksh ${_totalSpend.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                                style: AppTextStyles.headingSmall,
                              ),
                              Text(
                                _touchedIndex >= 0
                                    ? _categories[_touchedIndex]['label']
                                        as String
                                    : 'total spent',
                                style: AppTextStyles.labelSmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Legend
                    Wrap(
                      spacing: 16,
                      runSpacing: 10,
                      children: _categories.map((cat) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: cat['color'] as Color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              cat['label'] as String,
                              style: AppTextStyles.labelSmall,
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text('Breakdown', style: AppTextStyles.headingSmall),
              const SizedBox(height: 12),

              // Category list
              ..._categories.map((cat) => _CategoryCard(category: cat)),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Map<String, dynamic> category;
  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    final trendUp = category['trendUp'] as bool?;
    final trendColor = trendUp == null
        ? AppColors.textSecondary
        : trendUp
            ? AppColors.error
            : AppColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: (category['color'] as Color).withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              category['icon'] as IconData,
              color: category['color'] as Color,
              size: 22,
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
                      style:
                          AppTextStyles.headingSmall.copyWith(fontSize: 14),
                    ),
                    const Spacer(),
                    Text(
                      'Ksh ${(category['amount'] as int).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                      style:
                          AppTextStyles.headingSmall.copyWith(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: category['percent'] as double,
                          backgroundColor: AppColors.background,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            category['color'] as Color,
                          ),
                          minHeight: 5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      category['trend'] as String,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: trendColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${category['transactions']} transactions',
                  style: AppTextStyles.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}