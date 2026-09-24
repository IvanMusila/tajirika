import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  final List<String> _filters = [
    'All', 'Food', 'Transport', 'Family', 'Utilities', 'Other'
  ];

  final List<Map<String, dynamic>> _transactions = [
    {
      'merchant': 'Naivas Supermarket',
      'category': 'Groceries',
      'amount': -1200,
      'time': 'Today, 6:45 PM',
      'icon': Icons.shopping_cart_outlined,
      'color': const Color(0xFF8BC4A0),
      'ref': 'BM76YXKL',
      'type': 'Pay Bill',
    },
    {
      'merchant': 'Airtime Top-up',
      'category': 'Utilities',
      'amount': -50,
      'time': 'Today, 8:12 AM',
      'icon': Icons.phone_android_outlined,
      'color': const Color(0xFF64B5F6),
      'ref': 'BI90XKPL',
      'type': 'Airtime',
    },
    {
      'merchant': 'John Kamau',
      'category': 'Family Support',
      'amount': -2500,
      'time': 'Yesterday, 3:20 PM',
      'icon': Icons.person_outline_rounded,
      'color': const Color(0xFFFFB74D),
      'ref': 'BN23MKPL',
      'type': 'Send Money',
    },
    {
      'merchant': 'Uber',
      'category': 'Transport',
      'amount': -350,
      'time': 'Yesterday, 10:05 AM',
      'icon': Icons.directions_car_outlined,
      'color': const Color(0xFFBA68C8),
      'ref': 'BK44LXPQ',
      'type': 'Pay Bill',
    },
    {
      'merchant': 'Salary - Employer',
      'category': 'Income',
      'amount': 45000,
      'time': 'Sep 1, 9:00 AM',
      'icon': Icons.account_balance_outlined,
      'color': const Color(0xFF4CAF7D),
      'ref': 'BC11MNKL',
      'type': 'Received',
    },
    {
      'merchant': 'Java House',
      'category': 'Food & Drink',
      'amount': -780,
      'time': 'Sep 18, 1:15 PM',
      'icon': Icons.coffee_outlined,
      'color': const Color(0xFFFF8A65),
      'ref': 'BX99QRST',
      'type': 'Pay Bill',
    },
    {
      'merchant': '0798XXXXXX',
      'category': null,
      'amount': -15000,
      'time': 'Sep 1, 7:00 AM',
      'icon': Icons.help_outline_rounded,
      'color': const Color(0xFF9E9E9E),
      'ref': 'BZ01ABCD',
      'type': 'Send Money',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    return _transactions.where((t) {
      final matchesSearch = _searchController.text.isEmpty ||
          (t['merchant'] as String)
              .toLowerCase()
              .contains(_searchController.text.toLowerCase());
      final matchesFilter = _selectedFilter == 'All' ||
          (t['category'] as String? ?? '')
              .contains(_selectedFilter);
      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Transactions', style: AppTextStyles.headingLarge),
                  const SizedBox(height: 4),
                  Text(
                    '${_transactions.length} transactions this month',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 16),

                  // Search bar
                  Container(
                    height: 48,
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
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      style: AppTextStyles.bodyLarge.copyWith(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search transactions...',
                        hintStyle: AppTextStyles.bodyMedium,
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Filter chips
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filters.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final filter = _filters[index];
                        final isSelected = _selectedFilter == filter;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedFilter = filter),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
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
                              filter,
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
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Transaction list
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No transactions found',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final t = _filtered[index];
                        final isLast = index == _filtered.length - 1;
                        return _TransactionItem(
                          transaction: t,
                          isLast: isLast,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final bool isLast;

  const _TransactionItem({
    required this.transaction,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final amount = transaction['amount'] as int;
    final isCredit = amount > 0;
    final isUnknown = transaction['category'] == null;

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 32 : 10),
      padding: const EdgeInsets.all(14),
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
          // Icon
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: (transaction['color'] as Color).withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              transaction['icon'] as IconData,
              color: transaction['color'] as Color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction['merchant'] as String,
                  style: AppTextStyles.headingSmall.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (isUnknown)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Tap to label',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      Text(
                        '${transaction['category']}',
                        style: AppTextStyles.labelSmall,
                      ),
                    const SizedBox(width: 6),
                    Text(
                      '• ${transaction['time']}',
                      style: AppTextStyles.labelSmall,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Amount
          Text(
            '${isCredit ? '+' : '-'} Ksh ${amount.abs().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
            style: AppTextStyles.headingSmall.copyWith(
              fontSize: 14,
              color: isCredit ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}