import 'package:flutter/material.dart';

class AppConstants {
  // ألوان التطبيق
  static const Color primaryColor = Color(0xFF10b981); // Emerald
  static const Color primaryDark = Color(0xFF059669);
  static const Color accentColor = Color(0xFFfbbf24); // Amber
  static const Color successColor = Color(0xFF4ade80);
  static const Color dangerColor = Color(0xFFfb7185);
  static const Color backgroundLight = Color(0xFFecfdf5);
  static const Color textDark = Color(0xFF064e3b);
  
  // معلومات الشركة (يمكن تخصيصها من الإعدادات)
  static const String companyName = 'شركتك';
  static const String companyPhone = '07XX XXX XXXX';
  static const String companyAddress = 'بعقوبة، ديالى، العراق';
  
  // إعدادات التطبيق
  static const String appName = 'فواتير برو';
  static const String appNameEn = 'Invoices Pro';
  static const String databaseName = 'invoices_pro.db';
  static const int databaseVersion = 1;
  
  // أسماء الجداول
  static const String invoicesTable = 'invoices';
  static const String productsTable = 'products';
  static const String invoiceItemsTable = 'invoice_items';
  
  // حالات الفاتورة
  static const String statusUnpaid = 'unpaid';
  static const String statusPaid = 'paid';
  static const String statusPartial = 'partial';
  
  // تنسيقات التاريخ
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm';
  static const String displayDateFormat = 'dd/MM/yyyy';
  
  // إعدادات الطباعة
  static const double pdfPageWidth = 595.0; // A4
  static const double pdfPageHeight = 842.0;
  static const double pdfMargin = 40.0;
}

// ثيم التطبيق
class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    primaryColor: AppConstants.primaryColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppConstants.primaryColor,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Colors.grey[50],
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: AppConstants.primaryColor,
      foregroundColor: Colors.white,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppConstants.primaryColor,
      foregroundColor: Colors.white,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    fontFamily: 'Cairo',
  );
  
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    primaryColor: AppConstants.primaryColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppConstants.primaryColor,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Color(0xFF1E1E1E),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppConstants.primaryColor,
      foregroundColor: Colors.white,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2C2C2C)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2C2C2C)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    fontFamily: 'Cairo',
  );
}
