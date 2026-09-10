import 'package:flutter/material.dart';

/// Types d'opération
enum TransactionType { depense, revenu }

/// Catégories par défaut pour les dépenses
class DefaultCategories {
  static const List<Map<String, dynamic>> expense = [
    {'name': 'Alimentation', 'icon': Icons.restaurant},
    {'name': 'Transport', 'icon': Icons.directions_car},
    {'name': 'Logement', 'icon': Icons.home},
    {'name': 'Santé', 'icon': Icons.local_hospital},
    {'name': 'Éducation', 'icon': Icons.school},
    {'name': 'Téléphone / Internet', 'icon': Icons.phone_android},
    {'name': 'Loisirs', 'icon': Icons.sports_esports},
    {'name': 'Vêtements', 'icon': Icons.checkroom},
    {'name': 'Famille', 'icon': Icons.family_restroom},
    {'name': 'Commerce', 'icon': Icons.storefront},
    {'name': 'Factures', 'icon': Icons.receipt_long},
    {'name': 'Carburant', 'icon': Icons.local_gas_station},
    {'name': 'Autre', 'icon': Icons.category},
  ];

  static const List<Map<String, dynamic>> income = [
    {'name': 'Salaire', 'icon': Icons.work},
    {'name': 'Commerce', 'icon': Icons.storefront},
    {'name': 'Prime', 'icon': Icons.card_giftcard},
    {'name': 'Transfert', 'icon': Icons.swap_horiz},
    {'name': 'Cadeau', 'icon': Icons.redeem},
    {'name': 'Investissement', 'icon': Icons.trending_up},
    {'name': 'Autre', 'icon': Icons.category},
  ];
}

const List<String> paymentMethods = [
  'Espèces',
  'Mobile Money',
  'Carte bancaire',
  'Virement',
  'Autre',
];

/// Palette de couleurs de l'identité visuelle "MON BUDGET"
class AppColors {
  static const Color primary = Color(0xFF0E7C61); // vert financier moderne
  static const Color primaryDark = Color(0xFF0A5C48);
  static const Color income = Color(0xFF1E9E5A);
  static const Color expense = Color(0xFFD64545);
  static const Color background = Color(0xFFF6F8F7);
  static const Color card = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textLight = Color(0xFF6B7280);
  static const Color warning = Color(0xFFE8A33D);
  static const Color danger = Color(0xFFD64545);
}
