import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/themes/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/icon_mapper.dart';
import '../../models/analytics_model.dart';
import '../../repositories/transaction_repository.dart';
import '../../widgets/category_pie_chart.dart';
import '../../widgets/spending_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({
    super.key,
    required this.repository,
    required this.refreshToken,
  });

  final TransactionRepository repository;
  final int refreshToken;

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  AnalyticsBundle? _bundle;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AnalyticsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bundle = await widget.repository.loadAnalyticsData();
      if (!mounted) return;
      setState(() {
        _bundle = bundle;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null || _bundle == null) {
      return Center(
        child: FilledButton(onPressed: _load, child: const Text('Retry analytics')),
      );
    }

    final bundle = _bundle!;
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppConstants.pagePadding,
          12,
          AppConstants.pagePadding,
          130,
        ),
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE2D5),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.stay_current_portrait_rounded, color: AppColors.tertiary),
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
                icon: const Icon(Icons.notifications_outlined),
              ),
            ],
          ),
          const SizedBox(height: 28),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 820;
              final hero = _AnalyticsHero(summary: bundle.summary);
              final efficiency = _EfficiencyCard(bundle: bundle);
              if (stacked) {
                return Column(
                  children: [hero, const SizedBox(height: 18), efficiency],
                );
              }
              return Row(
                children: [
                  Expanded(flex: 2, child: hero),
                  const SizedBox(width: 18),
                  Expanded(child: efficiency),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(34),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Spending Trends',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLow,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Text('Monthly'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(onPressed: () {}, child: const Text('Weekly')),
                  ],
                ),
                const SizedBox(height: 18),
                SpendingChart(points: bundle.trends.take(7).toList()),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: AppColors.surfaceLow,
              borderRadius: BorderRadius.circular(34),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overview',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 18),
                _OverviewRow(
                  label: 'Monthly Average',
                  value: AppFormatters.currencyFromPaise(bundle.summary.totalSpending ~/ bundle.summary.month.clamp(1, 12)),
                  icon: Icons.calendar_month_rounded,
                  iconColor: AppColors.primary,
                  bgColor: AppColors.primaryContainer.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 18),
                _OverviewRow(
                  label: 'Weekly Burn',
                  value: AppFormatters.currencyFromPaise(bundle.summary.weeklyBurnRate),
                  icon: Icons.speed_rounded,
                  iconColor: AppColors.tertiary,
                  bgColor: AppColors.tertiaryContainer,
                ),
                const SizedBox(height: 18),
                Divider(color: AppColors.divider.withValues(alpha: 0.8)),
                const SizedBox(height: 18),
                Text(
                  'Savings Goal Progress',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: (bundle.efficiency.score / 100).clamp(0, 1),
                    minHeight: 8,
                    color: AppColors.secondary,
                    backgroundColor: AppColors.surfaceHighest,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${bundle.efficiency.score}% score this month',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(34),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Categories',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: CategoryPieChart(
                    categories: bundle.categories,
                    size: 220,
                    centerTitle: '${bundle.categories.length}',
                    centerSubtitle: 'CATEGORIES',
                  ),
                ),
                const SizedBox(height: 18),
                ...bundle.categories.take(3).map(
                      (category) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: AppFormatters.colorFromHex(category.color),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(category.name)),
                            Text('${category.percentage.toStringAsFixed(0)}%'),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(34),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'Top Merchants',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const Spacer(),
                    TextButton(onPressed: () {}, child: const Text('View All')),
                  ],
                ),
                const SizedBox(height: 12),
                ...bundle.topMerchants.map(
                  (merchant) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLow,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceHighest,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              iconFromBackendName('shopping_bag'),
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  merchant.merchantName,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${merchant.transactionCount} transactions',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                AppFormatters.currencyFromPaise(-merchant.totalAmount),
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: AppColors.tertiary,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                merchant.trendLabel,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: merchant.trendLabel.startsWith('Down')
                                          ? AppColors.secondary
                                          : AppColors.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsHero extends StatelessWidget {
  const _AnalyticsHero({required this.summary});

  final MonthlySummaryModel summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(34),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            bottom: 0,
            child: Icon(
              Icons.analytics_outlined,
              size: 110,
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL INSIGHTS',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 2,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                'Analytics',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontSize: 52,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    AppFormatters.currencyFromPaise(summary.totalSpending),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${summary.budgetAlertCount} alerts active',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.secondary,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EfficiencyCard extends StatelessWidget {
  const _EfficiencyCard({required this.bundle});

  final AnalyticsBundle bundle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(34),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EFFICIENCY SCORE',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white70,
                  letterSpacing: 2,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            '${bundle.efficiency.score}',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  fontSize: 72,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            bundle.efficiency.insight,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  height: 1.45,
                ),
          ),
        ],
      ),
    );
  }
}

class _OverviewRow extends StatelessWidget {
  const _OverviewRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: iconColor),
        ),
      ],
    );
  }
}

