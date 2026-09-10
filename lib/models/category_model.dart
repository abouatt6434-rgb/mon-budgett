import 'package:flutter/material.dart';
import '../utils/constants.dart';

class CategoryModel {
  final String id;
  final String name;
  final IconData icon;
  final TransactionType type;
  final bool isDefault;

  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.type,
    required this.isDefault,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon.codePoint,
      'type': type == TransactionType.depense ? 'depense' : 'revenu',
      'isDefault': isDefault ? 1 : 0,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: IconData(map['icon'] as int, fontFamily: 'MaterialIcons'),
      type: map['type'] == 'depense'
          ? TransactionType.depense
          : TransactionType.revenu,
      isDefault: (map['isDefault'] as int) == 1,
    );
  }
}
