import 'package:flutter/material.dart';

class MoreEntry {
  const MoreEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.builder,
    this.category,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final WidgetBuilder builder;
  final String? category;
}
