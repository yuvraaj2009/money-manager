class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.amount,
    required this.amountRupees,
    required this.flow,
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.categoryIcon,
    required this.description,
    required this.merchantName,
    required this.paymentMethod,
    required this.accountId,
    required this.accountName,
    required this.accountMaskedNumber,
    required this.date,
    required this.createdAt,
    this.referenceId,
    this.receiptUrl,
  });

  final String id;
  final int amount;
  final double amountRupees;
  final String flow;
  final String categoryId;
  final String categoryName;
  final String categoryColor;
  final String categoryIcon;
  final String description;
  final String merchantName;
  final String paymentMethod;
  final String accountId;
  final String accountName;
  final String accountMaskedNumber;
  final DateTime date;
  final DateTime createdAt;
  final String? referenceId;
  final String? receiptUrl;

  bool get isExpense => amount < 0;

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final amount = (json['amount'] as num?)?.toInt() ?? 0;
    final dateText = (json['date'] as String?) ?? DateTime.now().toIso8601String();
    final createdAtText = (json['created_at'] as String?) ?? dateText;
    final categoryName = (json['category_name'] ?? json['category'] ?? 'Uncategorized') as String;
    final accountName = (json['account_name'] ?? json['account'] ?? 'Household Account') as String;

    return TransactionModel(
      id: '${json['id'] ?? ''}',
      amount: amount,
      amountRupees: (json['amount_rupees'] as num?)?.toDouble() ?? amount / 100,
      flow: (json['flow'] as String?) ?? (amount < 0 ? 'expense' : 'income'),
      categoryId: (json['category_id'] ?? categoryName.toLowerCase().replaceAll(' ', '_')) as String,
      categoryName: categoryName,
      categoryColor: (json['category_color'] as String?) ?? '#0F52FF',
      categoryIcon: (json['category_icon'] as String?) ?? 'account_balance_wallet',
      description: (json['description'] as String?) ?? 'Transaction',
      merchantName: (json['merchant_name'] ?? json['description'] ?? 'Transaction') as String,
      paymentMethod: (json['payment_method'] as String?) ?? 'Cash',
      accountId: (json['account_id'] ?? accountName.toLowerCase().replaceAll(' ', '_')) as String,
      accountName: accountName,
      accountMaskedNumber: (json['account_masked_number'] as String?) ?? accountName,
      date: DateTime.parse(dateText),
      createdAt: DateTime.parse(createdAtText),
      referenceId: json['reference_id'] as String?,
      receiptUrl: json['receipt_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'amount_rupees': amountRupees,
        'flow': flow,
        'category_id': categoryId,
        'category_name': categoryName,
        'category_color': categoryColor,
        'category_icon': categoryIcon,
        'description': description,
        'merchant_name': merchantName,
        'payment_method': paymentMethod,
        'account_id': accountId,
        'account_name': accountName,
        'account_masked_number': accountMaskedNumber,
        'date': date.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'reference_id': referenceId,
        'receipt_url': receiptUrl,
      };
}
