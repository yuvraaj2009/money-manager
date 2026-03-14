import 'package:flutter/material.dart';

import '../../features/add_transaction/add_transaction_screen.dart';
import '../../features/transactions/transaction_detail_screen.dart';
import '../../features/transactions/transaction_list_screen.dart';
import '../../repositories/transaction_repository.dart';

class AppRouter {
  static Route<bool?> addTransaction(TransactionRepository repository) {
    return MaterialPageRoute<bool?>(
      builder: (_) => AddTransactionScreen(repository: repository),
    );
  }

  static Route<void> transactions(
    TransactionRepository repository,
    void Function(String transactionId) onOpenDetail,
  ) {
    return MaterialPageRoute<void>(
      builder: (_) => TransactionListScreen(
        repository: repository,
        onOpenDetail: onOpenDetail,
      ),
    );
  }

  static Route<void> transactionDetail(
    TransactionRepository repository,
    String transactionId,
  ) {
    return MaterialPageRoute<void>(
      builder: (_) => TransactionDetailScreen(
        repository: repository,
        transactionId: transactionId,
      ),
    );
  }
}
