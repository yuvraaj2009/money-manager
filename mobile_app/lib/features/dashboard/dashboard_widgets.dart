import 'package:flutter/material.dart';

import '../../core/themes/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/analytics_model.dart';
import '../../models/budget_model.dart';

class DashboardHeroCard extends StatelessWidget {
  const DashboardHeroCard({
    super.key,
    required this.balance,
    required this.changeLabel,
    required this.primaryMetricLabel,
    required this.primaryMetricValue,
    required this.secondaryMetricLabel,
    required this.secondaryMetricValue,
  });

  final int balance;
  final String changeLabel;
  final String primaryMetricLabel;
  final int primaryMetricValue;
  final String secondaryMetricLabel;
  final int secondaryMetricValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDim],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(34),
        boxShadow: const [
          BoxShadow(
            color: Color(0x330F52FF),
            blurRadius: 28,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'MONTHLY TOTAL BALANCE',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Colors.white70,
                              letterSpacing: 2,
                            ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Text(
                        changeLabel,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppFormatters.currencyFromPaise(balance),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontSize: 48,
                          height: 1,
                        ),
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: _MetricBlock(
                        label: primaryMetricLabel,
                        value: AppFormatters.currencyFromPaise(primaryMetricValue),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _MetricBlock(
                        label: secondaryMetricLabel,
                        value: AppFormatters.currencyFromPaise(secondaryMetricValue),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class QuickInsightCard extends StatelessWidget {
  const QuickInsightCard({
    super.key,
    required this.insight,
    required this.utilization,
  });

  final String insight;
  final BudgetUtilizationModel utilization;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighest,
        borderRadius: BorderRadius.circular(34),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'QUICK INSIGHT',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 2,
                    ),
              ),
              const Spacer(),
              const Icon(Icons.auto_graph_rounded, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Smart Budget',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            insight,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: (utilization.utilizationPercentage / 100).clamp(0, 1),
              backgroundColor: Colors.white,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryLegend extends StatelessWidget {
  const CategoryLegend({super.key, required this.categories});

  final List<CategoryTotalModel> categories;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 24,
      runSpacing: 14,
      children: categories.take(4).map((category) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppFormatters.colorFromHex(category.color),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              category.name,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        );
      }).toList(),
    );
  }
}
