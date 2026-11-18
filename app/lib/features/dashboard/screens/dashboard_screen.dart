import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/models/api_models.dart';
import '../../../core/utils/category_utils.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/services/sms_service.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: dashAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  size: 48,
                  color: AppColors.textHint,
                ),
                const SizedBox(height: 12),
                Text(
                  'Could not load dashboard',
                  style: AppTextStyles.headingSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Check that the backend is running',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => ref.refresh(dashboardProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (data) => _DashboardContent(data: data, ref: ref),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final DashboardResponse data;
  final WidgetRef ref;
  const _DashboardContent({required this.data, required this.ref});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => ref.refresh(dashboardProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
        ).copyWith(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const _Header(),
            const SizedBox(height: 24),
            _RunwayCard(
              runwayDays: data.runwayDays,
              balance: data.currentBalance,
              monthlyForecast: data.monthlyForecast,
            ),
            const SizedBox(height: 20),
            const _SpendOverviewCard(),
            const SizedBox(height: 20),
            const _SectionHeader(title: 'Spending breakdown'),
            const SizedBox(height: 12),
            _CategoriesSection(categories: data.categoryTotals),
            if (data.recentAnomalies.isNotEmpty) ...[
              const SizedBox(height: 20),
              _AnomalyAlert(anomaly: data.recentAnomalies.first),
            ],
            const SizedBox(height: 20),
            const _SectionHeader(title: 'Stats'),
            const SizedBox(height: 12),
            _StatsRow(data: data),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────

Future<void> _syncFromInbox(BuildContext context, WidgetRef ref) async {
  final status = await Permission.sms.request();
  if (!status.isGranted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('SMS permission required')));
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Reading M-Pesa messages…'),
      duration: Duration(seconds: 2),
    ),
  );

  final query = SmsQuery();

  final allMessages = await query.querySms(kinds: [SmsQueryKind.inbox]);

  final mpesaMessages = allMessages.where((m) {
    final body = m.body ?? '';
    return body.contains('Confirmed') &&
        body.contains('M-PESA') &&
        body.contains('New M-PESA balance is Ksh');
  }).toList();

  debugPrint(
    '[SMS] Total inbox: ${allMessages.length}, M-Pesa: ${mpesaMessages.length}',
  );

  final bodies = allMessages.map((m) => m.body ?? '').toList();
  final parsed = MpesaSmsParser.parseAll(bodies);
  final txBatch = parsed.map((p) => p.toJson()).toList();

  debugPrint(
    '[SMS] Parsed ${parsed.length} transactions from ${mpesaMessages.length} messages',
  );

  if (txBatch.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No M-Pesa transactions found in inbox')),
    );
    return;
  }

  final result = await ref.read(apiServiceProvider).syncTransactions(txBatch);
  final synced = result['synced'] ?? 0;
  final skipped = result['skipped'] ?? 0;

  ref.refresh(dashboardProvider);
  ref.refresh(forecastProvider);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Done — $synced new, $skipped already synced'),
      backgroundColor: AppColors.primary,
    ),
  );
}

// Future<void> _debugSmsAddresses(BuildContext context) async {
//   final status = await Permission.sms.request();
//   if (!status.isGranted) return;

//   final query    = SmsQuery();
//   // Read ALL inbox messages (no address filter)
//   final messages = await query.querySms(kinds: [SmsQueryKind.inbox]);

//   // Find all unique sender addresses
//   final addresses = messages.map((m) => m.address ?? 'null').toSet().toList();
//   addresses.sort();

//   debugPrint('=== ALL SMS SENDERS (${addresses.length}) ===');
//   for (final a in addresses) {
//     debugPrint('  "$a"');
//   }

//   // Show in a dialog
//   showDialog(
//     context: context,
//     builder: (_) => AlertDialog(
//       title: const Text('SMS Senders found'),
//       content: SizedBox(
//         width: double.maxFinite,
//         height: 300,
//         child: ListView(
//           children: addresses
//               .map((a) => ListTile(
//                     dense: true,
//                     title: Text(a, style: const TextStyle(fontSize: 13)),
//                   ))
//               .toList(),
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context),
//           child: const Text('Close'),
//         ),
//       ],
//     ),
//   );
// }

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Sync button
        Consumer(
          builder: (context, ref, _) {
            return GestureDetector(
              onTap: () => _syncFromInbox(context, ref),
              child: Container(
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
                  Icons.sync_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 10),
        // Notification bell (existing)
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
// Runway Card (real data)
// ─────────────────────────────────────────────
class _RunwayCard extends StatelessWidget {
  final int? runwayDays;
  final double balance;
  final double monthlyForecast;

  const _RunwayCard({
    required this.runwayDays,
    required this.balance,
    required this.monthlyForecast,
  });

  @override
  Widget build(BuildContext context) {
    final days = runwayDays ?? 0;
    final urgency = days <= 3
        ? AppColors.error
        : days <= 7
        ? AppColors.warning
        : AppColors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: urgency,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: urgency.withValues(alpha: 0.35),
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
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$days',
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
          Container(height: 1, color: Colors.white24),
          const SizedBox(height: 16),
          Row(
            children: [
              _RunwayStatItem(
                label: 'Balance',
                value: CategoryUtils.formatAmount(balance),
              ),
              Container(
                width: 1,
                height: 32,
                color: Colors.white24,
                margin: const EdgeInsets.symmetric(horizontal: 20),
              ),
              _RunwayStatItem(
                label: 'Monthly spend',
                value: CategoryUtils.formatAmount(monthlyForecast),
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
// Spend Overview Card (decorative chart)
// ─────────────────────────────────────────────
class _SpendOverviewCard extends StatelessWidget {
  const _SpendOverviewCard();

  final List<double> _weeklySpend = const [
    800,
    600,
    1200,
    400,
    2100,
    1800,
    500,
  ];
  final List<String> _days = const [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
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
              Text('Weekly pattern', style: AppTextStyles.labelSmall),
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
// Categories Section (real data)
// ─────────────────────────────────────────────
class _CategoriesSection extends StatelessWidget {
  final List<CategoryTotal> categories;
  const _CategoriesSection({required this.categories});

  @override
  Widget build(BuildContext context) {
    final display = categories
        .where((c) => c.category != 'invisible')
        .take(4)
        .toList();

    if (display.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text('No spend data yet', style: AppTextStyles.bodyMedium),
        ),
      );
    }

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
        children: display.map((cat) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _CategoryRow(cat: cat),
          );
        }).toList(),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final CategoryTotal cat;
  const _CategoryRow({required this.cat});

  @override
  Widget build(BuildContext context) {
    final color = CategoryUtils.color(cat.category);
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(CategoryUtils.icon(cat.category), color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    CategoryUtils.label(cat.category),
                    style: AppTextStyles.headingSmall.copyWith(fontSize: 14),
                  ),
                  const Spacer(),
                  Text(
                    CategoryUtils.formatAmount(cat.total),
                    style: AppTextStyles.headingSmall.copyWith(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: cat.percentage / 100,
                  backgroundColor: AppColors.background,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
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
// Anomaly Alert (real data)
// ─────────────────────────────────────────────
class _AnomalyAlert extends StatelessWidget {
  final AnomalySummary anomaly;
  const _AnomalyAlert({required this.anomaly});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
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
                  anomaly.severity == 'high'
                      ? 'Unusual spend detected'
                      : 'Spending alert',
                  style: AppTextStyles.headingSmall.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  anomaly.description.length > 60
                      ? '${anomaly.description.substring(0, 60)}...'
                      : anomaly.description,
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
// Stats Row (real data)
// ─────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final DashboardResponse data;
  const _StatsRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Total transactions',
            value: '${data.totalTransactions}',
            icon: Icons.receipt_long_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: '30-day spend',
            value: CategoryUtils.formatAmount(data.totalSpend30d),
            icon: Icons.trending_down_outlined,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.headingSmall.copyWith(fontSize: 15)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.labelSmall),
        ],
      ),
    );
  }
}
