import 'package:flutter/material.dart';

class MoreEntry {
  const MoreEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.builder,
    this.category,
    this.iconColor,
    this.iconBg,
    this.badge,
    this.badgeColor,
    this.badgeTextColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final WidgetBuilder builder;
  final String? category;
  final Color? iconColor;
  final Color? iconBg;
  final String? badge;
  final Color? badgeColor;
  final Color? badgeTextColor;
}
