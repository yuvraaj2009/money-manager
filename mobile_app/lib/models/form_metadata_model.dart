class CategoryOptionModel {
  const CategoryOptionModel({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
  });

  final String id;
  final String name;
  final String color;
  final String icon;

  factory CategoryOptionModel.fromJson(Map<String, dynamic> json) {
    return CategoryOptionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
      icon: json['icon'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color,
        'icon': icon,
      };
}

class AccountOptionModel {
  const AccountOptionModel({
    required this.id,
    required this.name,
    required this.type,
    required this.maskedNumber,
  });

  final String id;
  final String name;
  final String type;
  final String maskedNumber;

  factory AccountOptionModel.fromJson(Map<String, dynamic> json) {
    return AccountOptionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      maskedNumber: json['masked_number'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'masked_number': maskedNumber,
      };
}

class TransactionFormMetadataModel {
  const TransactionFormMetadataModel({
    required this.categories,
    required this.accounts,
    required this.paymentMethods,
  });

  final List<CategoryOptionModel> categories;
  final List<AccountOptionModel> accounts;
  final List<String> paymentMethods;

  factory TransactionFormMetadataModel.fromJson(Map<String, dynamic> json) {
    return TransactionFormMetadataModel(
      categories: (json['categories'] as List<dynamic>)
          .map((item) => CategoryOptionModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      accounts: (json['accounts'] as List<dynamic>)
          .map((item) => AccountOptionModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      paymentMethods: (json['payment_methods'] as List<dynamic>)
          .map((item) => item as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'categories': categories.map((c) => c.toJson()).toList(),
        'accounts': accounts.map((a) => a.toJson()).toList(),
        'payment_methods': paymentMethods,
      };
}
