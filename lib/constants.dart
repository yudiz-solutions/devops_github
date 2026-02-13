import 'package:flutter/material.dart';

class AppColors {
  // Background tones — warmer, less harsh
  static const background = Color(0xFF101624);
  static const sidebar = Color(0xFF141B2D);
  static const card = Color(0xFF1A2236);
  static const cardBorder = Color(0xFF2A3650);
  static const inputBg = Color(0xFF151D30);
  static const inputBorder = Color(0xFF334166);
  static const sidebarBorder = Color(0xFF232F47);

  // Accent / brand
  static const primary = Color(0xFF3B82F6);
  static const primaryDark = Color(0xFF2563EB);
  static const primaryLight = Color(0xFF60A5FA);
  static const accent = Color(0xFF8B5CF6);

  // Semantic
  static const danger = Color(0xFFEF4444);
  static const dangerDark = Color(0xFFDC2626);
  static const success = Color(0xFF34D399);
  static const successMuted = Color(0xFF10B981);
  static const warning = Color(0xFFFBBF24);

  // Text
  static const textPrimary = Color(0xFFF1F5F9);
  static const textSecondary = Color(0xFFA0AEC0);
  static const textMuted = Color(0xFF718096);
  static const link = Color(0xFF60A5FA);
  static const cyan = Color(0xFF67E8F9);

  // Log panel
  static const logBg = Color(0xFF0F1520);
  static const logBorder = Color(0xFF253045);

  // Status cards
  static const successCardBg = Color(0xFF0D2818);
  static const successCardBorder = Color(0xFF166534);
  static const warningCardBg = Color(0xFF1C1508);
  static const warningCardBorder = Color(0xFF854D0E);
  static const warningText = Color(0xFFCA8A04);

  // Sidebar active
  static const sidebarActive = Color(0xFF1E293B);
}

class AppRoles {
  static const List<Map<String, String>> roles = [
    {'value': 'push', 'label': 'Write'},
    {'value': 'pull', 'label': 'Read'},
    {'value': 'maintain', 'label': 'Maintain'},
    {'value': 'admin', 'label': 'Admin'},
    {'value': 'triage', 'label': 'Triage'},
  ];

  static String labelFor(String value) {
    return roles.firstWhere(
      (r) => r['value'] == value,
      orElse: () => {'value': value, 'label': value},
    )['label']!;
  }
}

const String defaultOwner = 'yudiz-solutions';
