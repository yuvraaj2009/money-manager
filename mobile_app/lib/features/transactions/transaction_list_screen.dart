import 'package:flutter/material.dart';

import '../../core/themes/app_theme.dart';
import '../../models/transaction_model.dart';
import '../../repositories/transaction_repository.dart';
import '../../widgets/transaction_card.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({
    super.key,
    required this.repository,
    required this.onOpenDetail,
  });

  final TransactionRepository repository;
  final ValueChanged<String> onOpenDetail;

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  bool _loading = true;
  Object? _error;
  List<TransactionModel> _transactions = const [];

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
      final transactions = await widget.repository.fetchTransactions();
      if (!mounted) return;
      setState(() {
        _transactions = transactions;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        centerTitle: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: FilledButton(onPressed: _load, child: const Text('Retry')))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = _transactions[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: TransactionCard(
                          transaction: transaction,
                          onTap: () => widget.onOpenDetail(transaction.id),
                        ),
                      );
                    },
                  ),
                ),
      backgroundColor: AppColors.background,
    );
  }
}
