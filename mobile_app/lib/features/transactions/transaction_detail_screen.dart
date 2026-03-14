import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/themes/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/icon_mapper.dart';
import '../../models/transaction_model.dart';
import '../../repositories/transaction_repository.dart';

class TransactionDetailScreen extends StatefulWidget {
  const TransactionDetailScreen({
    super.key,
    required this.repository,
    required this.transactionId,
  });

  final TransactionRepository repository;
  final String transactionId;

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  TransactionModel? _transaction;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final transaction = await widget.repository.fetchTransactionDetail(widget.transactionId);
      if (!mounted) return;
      setState(() {
        _transaction = transaction;
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

  Future<void> _downloadReceipt() async {
    final url = _transaction?.receiptUrl;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No receipt is attached to this transaction.')),
      );
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final transaction = _transaction;
    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null || transaction == null
                ? Center(
                    child: FilledButton(onPressed: _load, child: const Text('Retry detail')),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 130),
                    children: [
                      Row(
                        children: [
                          IconButton.filledTonal(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            'Money Manager',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const Spacer(),
                          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_outlined)),
                          const CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.surfaceHighest,
                            child: Icon(Icons.person_rounded, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text('COMPLETED', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppFormatters.currencyFromPaise(transaction.amount),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Text(
                            AppFormatters.detailDate(transaction.createdAt),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.tonalIcon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Edit flow can be added next.')),
                                );
                              },
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Edit'),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Delete endpoint is not implemented yet.')),
                                );
                              },
                              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF64D70)),
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Delete'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Transaction Details', style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 24),
                            _DetailRow(
                              label: 'CATEGORY',
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: AppFormatters.colorFromHex(transaction.categoryColor).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      iconFromBackendName(transaction.categoryIcon),
                                      color: AppFormatters.colorFromHex(transaction.categoryColor),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(transaction.categoryName),
                                ],
                              ),
                            ),
                            _DetailRow(
                              label: 'PAYMENT METHOD',
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(Icons.credit_card_rounded, color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 12),
                                  Text('${transaction.paymentMethod} - ${transaction.accountMaskedNumber}'),
                                ],
                              ),
                            ),
                            _DetailRow(label: 'SOURCE', child: Text(transaction.accountName)),
                            _DetailRow(label: 'REFERENCE ID', child: Text(transaction.referenceId ?? 'Not generated')),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLow,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DESCRIPTION',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    letterSpacing: 2,
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              transaction.description,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'RECEIPT ATTACHMENT',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    letterSpacing: 2,
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                            const SizedBox(height: 18),
                            AspectRatio(
                              aspectRatio: 3 / 4,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: transaction.receiptUrl == null
                                    ? Container(
                                        color: AppColors.surfaceLow,
                                        child: const Center(child: Text('No receipt attached')),
                                      )
                                    : Image.network(
                                        transaction.receiptUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          color: AppColors.surfaceLow,
                                          child: const Center(child: Text('Receipt preview unavailable')),
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            OutlinedButton.icon(
                              onPressed: _downloadReceipt,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                              ),
                              icon: const Icon(Icons.download_rounded),
                              label: const Text('Download JPG'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'HISTORY',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    letterSpacing: 2,
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                            const SizedBox(height: 18),
                            _HistoryItem(
                              color: AppColors.secondary,
                              title: 'Created automatically',
                              subtitle: AppFormatters.detailDate(transaction.createdAt),
                            ),
                            const SizedBox(height: 18),
                            _HistoryItem(
                              color: AppColors.primary,
                              title: 'Status updated to Completed',
                              subtitle: AppFormatters.detailDate(transaction.createdAt),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
      backgroundColor: AppColors.background,
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 2,
                ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ],
    );
  }
}

