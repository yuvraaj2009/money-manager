import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/notification_service.dart';
import '../../core/themes/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/icon_mapper.dart';
import '../../models/analytics_model.dart';
import '../../models/budget_model.dart';
import '../../models/form_metadata_model.dart';
import '../../repositories/transaction_repository.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({
    super.key,
    required this.repository,
    required this.refreshToken,
    required this.onBudgetChanged,
  });

  final TransactionRepository repository;
  final int refreshToken;
  final VoidCallback onBudgetChanged;

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  BudgetBundle? _bundle;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant BudgetScreen oldWidget) {
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

    if (_bundle == null) {
      final cached = await widget.repository.loadBudgetDataFromCache();
      if (cached != null && mounted) {
        setState(() {
          _bundle = cached;
          _loading = false;
        });
      }
    }

    try {
      final bundle = await widget.repository.loadBudgetData();
      if (!mounted) return;
      setState(() {
        _bundle = bundle;
        _loading = false;
      });
      unawaited(
        NotificationService.instance.showBudgetThresholdNotifications(
          bundle.utilization,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      if (_bundle == null) {
        setState(() {
          _error = error;
          _loading = false;
        });
      }
    }
  }

  Future<void> _createBudget() async {
    final metadata = _bundle?.metadata;
    if (metadata == null) {
      return;
    }
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _BudgetDialog(
        metadata: metadata,
        onSave: (categoryId, amount) async {
          await widget.repository
              .saveBudget(categoryId: categoryId, monthlyLimit: amount);
          widget.onBudgetChanged();
          await _load();
        },
      ),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget saved successfully.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null || _bundle == null) {
      return Center(
        child:
            FilledButton(onPressed: _load, child: const Text('Retry budgets')),
      );
    }

    final bundle = _bundle!;
    final alerts = bundle.utilization.alerts;
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
                  icon: const Icon(Icons.notifications_outlined)),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'CURRENT PERIOD: ${AppFormatters.monthLabel(bundle.summary.month).toUpperCase()} ${bundle.summary.year}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 2,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'Monthly\nLedger',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your household spending is currently at ${bundle.utilization.utilizationPercentage.toStringAsFixed(0)}% of the total budget. You have ${AppFormatters.currencyFromPaise(bundle.utilization.totalBudget - bundle.utilization.totalSpent)} remaining for the month.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 22),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _createBudget,
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                backgroundColor: AppColors.primary,
              ),
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: const Text('Create Budget'),
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 860;
              final alertsCard = _BudgetAlertsCard(alerts: alerts);
              final categoriesCard = _BudgetListCard(budgets: bundle.budgets);
              if (stacked) {
                return Column(
                  children: [
                    alertsCard,
                    const SizedBox(height: 18),
                    categoriesCard
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: alertsCard),
                  const SizedBox(width: 18),
                  Expanded(flex: 2, child: categoriesCard),
                ],
              );
            },
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 860;
              final savingsCard = _SavingsCard(summary: bundle.summary);
              final utilizationCard = _UtilizationCard(bundle: bundle);
              if (stacked) {
                return Column(
                  children: [
                    savingsCard,
                    const SizedBox(height: 18),
                    utilizationCard
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: savingsCard),
                  const SizedBox(width: 18),
                  Expanded(flex: 2, child: utilizationCard),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BudgetAlertsCard extends StatelessWidget {
  const _BudgetAlertsCard({required this.alerts});

  final List<BudgetAlertModel> alerts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(34),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.tertiaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: AppColors.tertiary),
          ),
          const SizedBox(height: 18),
          Text(
            'Budget Alerts',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Immediate attention required for ${alerts.length} categories.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 18),
          if (alerts.isEmpty)
            const Text('No active alerts right now.')
          else
            ...alerts.take(2).map(
                  (alert) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 42,
                            decoration: BoxDecoration(
                              color: alert.severity == 'high'
                                  ? AppColors.tertiary
                                  : AppColors.primary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  alert.categoryName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  alert.overAmount > 0
                                      ? 'Over by ${AppFormatters.currencyFromPaise(alert.overAmount)}'
                                      : '${alert.utilizationPercentage.toStringAsFixed(0)}% of ${AppFormatters.currencyFromPaise(alert.monthlyLimit)} used',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.tertiary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _BudgetListCard extends StatelessWidget {
  const _BudgetListCard({required this.budgets});

  final List<BudgetModel> budgets;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(34),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  'Spending Categories',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text('List View'),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(onPressed: () {}, child: const Text('Analytics')),
            ],
          ),
          const SizedBox(height: 20),
          ...budgets.map(
            (budget) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: budget.status == 'exceeded'
                      ? Border.all(
                          color: AppColors.tertiary.withValues(alpha: 0.18),
                          width: 1.4)
                      : null,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color:
                                AppFormatters.colorFromHex(budget.categoryColor)
                                    .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            iconFromBackendName(budget.categoryIcon),
                            color: AppFormatters.colorFromHex(
                                budget.categoryColor),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                budget.categoryName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                budget.status == 'safe'
                                    ? 'Next refill in 4 days'
                                    : budget.status == 'caution'
                                        ? 'Approaching monthly limit'
                                        : 'Exceeded monthly limit',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: budget.status == 'exceeded'
                                          ? AppColors.tertiary
                                          : AppColors.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${AppFormatters.currencyFromPaise(budget.spentAmount)} / ${AppFormatters.currencyFromPaise(budget.monthlyLimit)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                budget.status.toUpperCase(),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: budget.status == 'safe'
                                          ? AppColors.secondary
                                          : budget.status == 'caution'
                                              ? AppColors.primary
                                              : AppColors.tertiary,
                                      letterSpacing: 1.4,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 10,
                        value: (budget.utilizationPercentage / 100).clamp(0, 1),
                        color: budget.status == 'safe'
                            ? AppColors.secondary
                            : budget.status == 'caution'
                                ? AppColors.primaryDim
                                : AppColors.tertiary,
                        backgroundColor: AppColors.surfaceHigh,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SavingsCard extends StatelessWidget {
  const _SavingsCard({required this.summary});

  final MonthlySummaryModel summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: const Color(0xFF08742A),
        borderRadius: BorderRadius.circular(34),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL SAVINGS',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white70,
                  letterSpacing: 2,
                ),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              AppFormatters.currencyFromPaise(summary.netCashFlow),
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              const Icon(Icons.trending_up_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                '+12.5% this month',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UtilizationCard extends StatelessWidget {
  const _UtilizationCard({required this.bundle});

  final BudgetBundle bundle;

  @override
  Widget build(BuildContext context) {
    final maxAmount = bundle.utilization.dailySpend
        .fold<int>(0, (max, item) => item.amount > max ? item.amount : max);
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(34),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Budget Utilization',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: bundle.utilization.dailySpend.map((day) {
                final double factor = (maxAmount == 0
                        ? 0.15
                        : (day.amount / maxAmount).clamp(0.12, 1.0))
                    .toDouble();
                final color = day.isToday
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.22);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: 82 * factor,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          day.label.substring(0, 3).toUpperCase(),
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: day.isToday
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetDialog extends StatefulWidget {
  const _BudgetDialog({required this.metadata, required this.onSave});

  final TransactionFormMetadataModel metadata;
  final Future<void> Function(String categoryId, int amount) onSave;

  @override
  State<_BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<_BudgetDialog> {
  final _controller = TextEditingController();
  String? _categoryId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.metadata.categories.first.id;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create or update budget'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _categoryId,
            items: widget.metadata.categories
                .map(
                  (category) => DropdownMenuItem<String>(
                    value: category.id,
                    child: Text(category.name),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _categoryId = value),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration:
                const InputDecoration(labelText: 'Monthly limit in rupees'),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: _saving
              ? null
              : () async {
                  final value = double.tryParse(_controller.text.trim());
                  if (value == null || value <= 0 || _categoryId == null) {
                    return;
                  }
                  setState(() => _saving = true);
                  await widget.onSave(_categoryId!, (value * 100).round());
                  if (context.mounted) {
                    Navigator.pop(context, true);
                  }
                },
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}


