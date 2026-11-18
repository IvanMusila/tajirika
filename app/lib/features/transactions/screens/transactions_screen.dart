import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/models/api_models.dart';
import '../../../core/utils/category_utils.dart';

const _kFilters = [
  ('All',          'all'),
  ('Necessity',    'necessity'),
  ('Convenience',  'convenience'),
  ('Social',       'social'),
  ('Aspirational', 'aspirational'),
  ('Invisible',    'invisible'),
];

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});
  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  String _selectedCategory = 'all';
  String _searchQuery      = '';

  final List<TransactionModel> _transactions = [];
  int    _offset       = 0;
  int    _total        = 0;
  bool   _isLoading    = false;
  bool   _hasMore      = true;
  String? _error;

  static const int _pageSize = 50;

  @override
  void initState() {
    super.initState();
    _load();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    if (_isLoading) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final result = await ref.read(apiServiceProvider).getTransactions(
        category: _selectedCategory == 'all' ? null : _selectedCategory,
        search:   _searchQuery.isEmpty ? null : _searchQuery,
        limit:    _pageSize,
        offset:   _offset,
      );
      setState(() {
        _transactions.addAll(result.transactions);
        _total   = result.total;
        _offset += result.transactions.length;
        _hasMore = result.transactions.length == _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    await _load();
  }

  Future<void> _reload() async {
    setState(() {
      _transactions.clear();
      _offset  = 0;
      _hasMore = true;
      _error   = null;
    });
    await _load();
  }

  void _onFilterChanged(String value) {
    if (value == _selectedCategory) return;
    _selectedCategory = value;
    _reload();
  }

  void _onSearchChanged(String value) {
    _searchQuery = value;
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text('Transactions', style: AppTextStyles.headingLarge),
                    const Spacer(),
                    Text('$_total total', style: AppTextStyles.labelSmall),
                  ]),
                  const SizedBox(height: 16),

                  // Search bar
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [BoxShadow(
                          color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2))],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: AppTextStyles.bodyLarge.copyWith(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search merchants…',
                        hintStyle: AppTextStyles.bodyMedium,
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppColors.textSecondary, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear,
                                    size: 18, color: AppColors.textSecondary),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Filter chips
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _kFilters.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final (label, value) = _kFilters[i];
                        final isSelected = _selectedCategory == value;
                        return GestureDetector(
                          onTap: () => _onFilterChanged(value),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [BoxShadow(
                                  color: AppColors.shadow, blurRadius: 6, offset: Offset(0, 2))],
                            ),
                            child: Text(label,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: isSelected ? Colors.white : AppColors.textSecondary,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                )),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // ── List ──────────────────────────────────────────────────
            Expanded(
              child: _error != null && _transactions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.wifi_off_rounded,
                              size: 40, color: AppColors.textHint),
                          const SizedBox(height: 12),
                          Text('Could not load transactions',
                              style: AppTextStyles.bodyMedium),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _reload,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _transactions.isEmpty && _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary))
                      : _transactions.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.receipt_long_outlined,
                                      size: 48, color: AppColors.textHint),
                                  const SizedBox(height: 12),
                                  Text('No transactions found',
                                      style: AppTextStyles.bodyMedium),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              color: AppColors.primary,
                              onRefresh: _reload,
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.symmetric(horizontal: 20)
                                    .copyWith(bottom: 100),
                                itemCount:
                                    _transactions.length + (_hasMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == _transactions.length) {
                                    return const Padding(
                                      padding: EdgeInsets.all(20),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                            color: AppColors.primary),
                                      ),
                                    );
                                  }
                                  return _TransactionItem(
                                    tx:     _transactions[index],
                                    isLast: index == _transactions.length - 1,
                                    onLabel: (category) async {
                                      await ref
                                          .read(apiServiceProvider)
                                          .labelTransaction(
                                              _transactions[index].id, category);
                                      _reload();
                                    },
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final TransactionModel tx;
  final bool isLast;
  final Future<void> Function(String) onLabel;
  const _TransactionItem({required this.tx, required this.isLast, required this.onLabel});

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) {
      final h    = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final m    = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return 'Today, $h:$m $ampm';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }
    return '${dt.day}/${dt.month}/${dt.year % 100}';
  }

  void _showLabelSheet(BuildContext context) {
    const categories = [
      'necessity', 'convenience', 'social', 'aspirational', 'invisible',
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Label transaction', style: AppTextStyles.headingSmall),
            const SizedBox(height: 4),
            Text(tx.merchantName, style: AppTextStyles.bodyMedium),
            const SizedBox(height: 20),
            ...categories.map((cat) {
              final color = CategoryUtils.color(cat);
              return ListTile(
                leading: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(CategoryUtils.icon(cat), color: color, size: 18),
                ),
                title: Text(CategoryUtils.label(cat),
                    style: AppTextStyles.headingSmall.copyWith(fontSize: 14)),
                trailing: tx.category == cat
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () { Navigator.pop(context); onLabel(cat); },
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isReview = tx.category == 'review';
    final color    = CategoryUtils.color(tx.category);
    return GestureDetector(
      onTap: isReview ? () => _showLabelSheet(context) : null,
      child: Container(
        margin: EdgeInsets.only(bottom: isLast ? 32 : 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: isReview
              ? Border.all(color: AppColors.warning.withValues(alpha: 0.4))
              : null,
          boxShadow: const [BoxShadow(
              color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(CategoryUtils.icon(tx.category), color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.merchantName.isEmpty ? tx.transactionType : tx.merchantName,
                    style: AppTextStyles.headingSmall.copyWith(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(children: [
                    if (isReview)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Tap to label',
                            style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.warning, fontWeight: FontWeight.w600)),
                      )
                    else
                      Text(CategoryUtils.label(tx.category),
                          style: AppTextStyles.labelSmall),
                    const SizedBox(width: 6),
                    Text('• ${_formatTime(tx.timestamp)}',
                        style: AppTextStyles.labelSmall),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${tx.isDebit ? '-' : '+'} ${CategoryUtils.formatAmount(tx.amount)}',
              style: AppTextStyles.headingSmall.copyWith(
                fontSize: 13,
                color: tx.isDebit ? AppColors.error : AppColors.success,
              ),
            ),
          ],
        ),
      ),
    );
  }
}