import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/models/api_models.dart';
import '../../../core/utils/category_utils.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});
  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final dashAsync = ref.watch(dashboardProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: dashAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textHint),
              const SizedBox(height: 12),
              Text('Could not load categories', style: AppTextStyles.headingSmall),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: () => ref.refresh(dashboardProvider), child: const Text('Retry')),
            ]),
          ),
          data: (data) {
            final cats  = data.categoryTotals;
            final total = cats.fold(0.0, (s, c) => s + c.total);
            final visual = cats.where((c) => c.category != 'invisible').toList();
            final visualTotal = visual.fold(0.0, (s, c) => s + c.total);
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => ref.refresh(dashboardProvider),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 100),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SizedBox(height: 20),
                  Text('Categories', style: AppTextStyles.headingLarge),
                  const SizedBox(height: 4),
                  Text('Last 30 days · ${CategoryUtils.formatAmount(total)} total',
                      style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 24),
                  if (visual.isNotEmpty)
                    _DonutCard(
                      categories: visual, totalAmount: visualTotal,
                      touchedIndex: _touchedIndex,
                      onTouch: (i) => setState(() => _touchedIndex = i),
                    ),
                  const SizedBox(height: 20),
                  Text('Breakdown', style: AppTextStyles.headingSmall),
                  const SizedBox(height: 12),
                  ...cats.map((cat) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _CategoryCard(cat: cat, total: total),
                  )),
                  const SizedBox(height: 32),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DonutCard extends StatelessWidget {
  final List<CategoryTotal> categories;
  final double totalAmount;
  final int? touchedIndex;
  final ValueChanged<int?> onTouch;
  const _DonutCard({required this.categories, required this.totalAmount, required this.touchedIndex, required this.onTouch});

  @override
  Widget build(BuildContext context) {
    final touched = touchedIndex != null && touchedIndex! < categories.length ? categories[touchedIndex!] : null;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 16, offset: Offset(0, 4))],
      ),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          SizedBox(width: 160, height: 160,
            child: PieChart(PieChartData(
              pieTouchData: PieTouchData(touchCallback: (event, response) {
                if (!event.isInterestedForInteractions || response == null || response.touchedSection == null) {
                  onTouch(null); return;
                }
                onTouch(response.touchedSection!.touchedSectionIndex);
              }),
              centerSpaceRadius: 48, sectionsSpace: 2,
              sections: categories.asMap().entries.map((e) {
                final isTouched = touchedIndex == e.key;
                final color = CategoryUtils.color(e.value.category);
                return PieChartSectionData(
                  value: e.value.total, color: color,
                  radius: isTouched ? 36 : 28, title: '',
                  borderSide: isTouched ? BorderSide(color: color, width: 3) : BorderSide.none,
                );
              }).toList(),
            )),
          ),
          const SizedBox(width: 20),
          Expanded(child: touched != null
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 10, height: 10,
                    decoration: BoxDecoration(color: CategoryUtils.color(touched.category), shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(CategoryUtils.label(touched.category),
                      style: AppTextStyles.headingSmall.copyWith(fontSize: 14)),
                ]),
                const SizedBox(height: 8),
                Text(CategoryUtils.formatAmount(touched.total),
                    style: AppTextStyles.headingMedium.copyWith(color: AppColors.primary)),
                const SizedBox(height: 4),
                Text('${touched.percentage.toStringAsFixed(1)}% of total', style: AppTextStyles.bodyMedium),
                Text('${touched.count} transactions', style: AppTextStyles.labelSmall),
              ])
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Total spend', style: AppTextStyles.bodyMedium),
                const SizedBox(height: 4),
                Text(CategoryUtils.formatAmount(totalAmount),
                    style: AppTextStyles.headingMedium.copyWith(color: AppColors.primary)),
                const SizedBox(height: 12),
                Text('Tap a segment\nfor details', style: AppTextStyles.labelSmall),
              ]),
          ),
        ]),
        const SizedBox(height: 20),
        Wrap(spacing: 12, runSpacing: 8,
          children: categories.map((c) {
            final color = CategoryUtils.color(c.category);
            return Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(CategoryUtils.label(c.category),
                  style: AppTextStyles.labelSmall.copyWith(fontSize: 11)),
            ]);
          }).toList(),
        ),
      ]),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryTotal cat;
  final double total;
  const _CategoryCard({required this.cat, required this.total});

  @override
  Widget build(BuildContext context) {
    final color = CategoryUtils.color(cat.category);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(children: [
        Container(width: 48, height: 48,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
          child: Icon(CategoryUtils.icon(cat.category), color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(CategoryUtils.label(cat.category),
                style: AppTextStyles.headingSmall.copyWith(fontSize: 15)),
            const Spacer(),
            Text(CategoryUtils.formatAmount(cat.total),
                style: AppTextStyles.headingSmall.copyWith(fontSize: 15)),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total > 0 ? cat.total / total : 0,
                backgroundColor: AppColors.background,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            )),
            const SizedBox(width: 10),
            Text('${cat.percentage.toStringAsFixed(1)}%',
                style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 4),
          Text('${cat.count} transactions', style: AppTextStyles.labelSmall),
        ])),
      ]),
    );
  }
}