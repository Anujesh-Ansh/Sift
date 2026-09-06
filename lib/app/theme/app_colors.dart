import 'package:flutter/material.dart';

/// Semantic, curated color palette for Project Sift.
class AppColors {
  AppColors._();

  // Primary brand palette (Indigo / Violet)
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color secondary = Color(0xFF06B6D4);
  static const Color accent = Color(0xFFF43F5E);

  // Dark surface colors (Default theme)
  static const Color darkBackground = Color(0xFF0A0D14);
  static const Color darkSurface = Color(0xFF121722);
  static const Color darkSurfaceElevated = Color(0xFF1A2234);
  static const Color darkCard = Color(0xFF161E2E);
  static const Color darkBorder = Color(0xFF263248);

  // Light surface colors
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF1F5F9);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // Status & Feedback
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Text Colors
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);
  static const Color textTertiaryDark = Color(0xFF64748B);

  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textMutedLight = Color(0xFF94A3B8);

  // Category Accent Colors for Badges & Filters
  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'finance':
        return const Color(0xFF10B981); // Emerald
      case 'shopping':
        return const Color(0xFFF59E0B); // Amber
      case 'work':
        return const Color(0xFF6366F1); // Indigo
      case 'communication':
        return const Color(0xFF06B6D4); // Cyan
      case 'travel':
        return const Color(0xFF3B82F6); // Blue
      case 'food':
        return const Color(0xFFF97316); // Orange
      case 'entertainment':
        return const Color(0xFFA855F7); // Purple
      case 'education':
        return const Color(0xFF14B8A6); // Teal
      case 'technology':
        return const Color(0xFF0EA5E9); // Sky
      case 'health':
        return const Color(0xFFEC4899); // Pink
      case 'documents':
        return const Color(0xFF64748B); // Slate
      case 'social':
        return const Color(0xFF8B5CF6); // Violet
      case 'reference':
        return const Color(0xFFD97706); // Warm Amber
      case 'aesthetic':
        return const Color(0xFFE11D48); // Rose
      default:
        return const Color(0xFF94A3B8); // Muted Slate
    }
  }
}
