import 'package:flutter/material.dart';

IconData iconFromBackendName(String name) {
  switch (name) {
    case 'home':
      return Icons.home_rounded;
    case 'restaurant':
      return Icons.restaurant_rounded;
    case 'movie':
      return Icons.movie_creation_outlined;
    case 'shopping_cart':
      return Icons.shopping_cart_rounded;
    case 'shopping_bag':
      return Icons.shopping_bag_outlined;
    case 'commute':
      return Icons.directions_bus_rounded;
    case 'bolt':
      return Icons.bolt_rounded;
    case 'payments':
      return Icons.payments_rounded;
    case 'spa':
      return Icons.spa_outlined;
    case 'health_and_safety':
      return Icons.health_and_safety_outlined;
    default:
      return Icons.account_balance_wallet_outlined;
  }
}
