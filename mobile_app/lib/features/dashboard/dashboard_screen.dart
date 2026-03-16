import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/notification_service.dart';
import '../../core/themes/app_theme.dart';
import '../../repositories/transaction_repository.dart';
import '../../widgets/category_pie_chart.dart';
import '../../widgets/transaction_card.dart';
import 'dashboard_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.repository,
    required this.refreshToken,
    required this.onViewAnalytics,
    required this.onViewBudgets,
    required this.onViewTransactions,
    required this.onOpenTransactionDetail,
  });

  final TransactionRepository repository;
  final int refreshToken;
  final VoidCallback onViewAnalytics;
  final VoidCallback onViewBudgets;
  final VoidCallback onViewTransactions;
  final ValueChanged<String> onOpenTransactionDetail;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardBundle? _bundle;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = _bundle == null;
      _error = null;
    });

    // Show cached data instantly while network loads
    if (_bundle == null) {
      final cached = await widget.repository.loadDashboardDataFromCache();
      if (cached != null && mounted) {
        setState(() {
          _bundle = cached;
          _loading = false;
        });
      }
    }

    try {
      final bundle = await widget.repository.loadDashboardData();
      if (!mounted) return;
      setState(() {
        _bundle = bundle;
        _loading = false;
      });
      unawaited(
        NotificationService.instance.showBudgetThresholdNotifications(
          bundle.budgetUtilization,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      // Only show error if we have no data at all
      if (_bundle == null) {
        setState(() {
          _error = error;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null || _bundle == null) {
      return _ErrorState(onRetry: _load);
    }

    final bundle = _bundle!;
    final currentMonth = bundle.summary.month - 1;
    final previousMonth = currentMonth > 0
        ? bundle.yearSummary.monthlyBreakdown[currentMonth - 1]
        : null;
    final currentPoint = bundle.yearSummary.monthlyBreakdown[currentMonth];
    final changeLabel =
        _buildChangeLabel(currentPoint.netFlow, previousMonth?.netFlow ?? 0);
    final alert = bundle.budgetUtilization.alerts.isNotEmpty
        ? bundle.budgetUtilization.alerts.first
        : null;
    final quickInsight = alert == null
        ? bundle.summary.insight
        : '${alert.categoryName} is at ${alert.utilizationPercentage.toStringAsFixed(0)}% of budget. Consider slowing down this week.';

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppConstants.pagePadding,
          12,
          AppConstants.pagePadding,
          130,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _TopBar(),
            const SizedBox(height: 28),
            LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 820;
                if (stacked) {
                  return Column(
                    children: [
                      DashboardHeroCard(
                        balance: bundle.summary.netCashFlow,
                        changeLabel: changeLabel,
                        primaryMetricLabel: 'Yearly Savings',
                        primaryMetricValue: bundle.yearSummary.netCashFlow,
                        secondaryMetricLabel: 'Weekly Burn',
                        secondaryMetricValue: bundle.summary.weeklyBurnRate,
                      ),
                      const SizedBox(height: 20),
                      QuickInsightCard(
                        insight: quickInsight,
                        utilization: bundle.budgetUtilization,
                      ),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: DashboardHeroCard(
                        balance: bundle.summary.netCashFlow,
                        changeLabel: changeLabel,
                        primaryMetricLabel: 'Yearly Savings',
                        primaryMetricValue: bundle.yearSummary.netCashFlow,
                        secondaryMetricLabel: 'Weekly Burn',
                        secondaryMetricValue: bundle.summary.weeklyBurnRate,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: QuickInsightCard(
                        insight: quickInsight,
                        utilization: bundle.budgetUtilization,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 36),
            Row(
              children: [
                Text(
                  'Allocations',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: widget.onViewAnalytics,
                  child: const Text('View Report'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(34),
              ),
              child: Column(
                children: [
                  CategoryPieChart(categories: bundle.categories, size: 250),
                  const SizedBox(height: 20),
                  CategoryLegend(categories: bundle.categories),
                ],
              ),
            ),
            const SizedBox(height: 36),
            Row(
              children: [
                Text(
                  'Recent Ledger',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Text('All'),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: widget.onViewTransactions,
                  child: const Text('Expenses'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              children: bundle.recentTransactions
                  .map(
                    (transaction) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TransactionCard(
                        transaction: transaction,
                        onTap: () =>
                            widget.onOpenTransactionDetail(transaction.id),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _buildChangeLabel(int current, int previous) {
    if (previous == 0) {
      return 'Fresh month';
    }
    final delta = ((current - previous) / previous.abs()) * 100;
    final rounded = delta.abs().toStringAsFixed(1);
    return '${delta >= 0 ? '+' : '-'}$rounded% vs last month';
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFFFE2D5),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Icon(Icons.stay_current_portrait_rounded,
              color: AppColors.tertiary),
        ),
        const SizedBox(width: 14),
        Text(
          'Money Manager',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.light_mode_outlined),
          color: AppColors.textPrimary,
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_outlined),
              color: AppColors.textPrimary,
            ),
            const Positioned(
              right: 12,
              top: 10,
              child:
                  CircleAvatar(radius: 4, backgroundColor: AppColors.tertiary),
            ),
          ],
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Unable to load dashboard data.',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}


