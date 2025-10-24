import 'package:intl/intl.dart';

class Helpers {
  // تحويل الأرقام الإنجليزية إلى عربية
  static String toArabicNumbers(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    
    String output = input;
    for (int i = 0; i < english.length; i++) {
      output = output.replaceAll(english[i], arabic[i]);
    }
    return output;
  }
  
  // تحويل الأرقام العربية إلى إنجليزية
  static String toEnglishNumbers(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    
    String output = input;
    for (int i = 0; i < arabic.length; i++) {
      output = output.replaceAll(arabic[i], english[i]);
    }
    return output;
  }
  
  // تنسيق المبلغ بفواصل الآلاف
  static String formatCurrency(double amount, {bool useArabicNumbers = true}) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    String formatted = formatter.format(amount);
    return useArabicNumbers ? toArabicNumbers(formatted) : formatted;
  }
  
  // تنسيق التاريخ
  static String formatDate(DateTime date, {bool useArabicNumbers = true}) {
    final formatter = DateFormat('dd/MM/yyyy');
    String formatted = formatter.format(date);
    return useArabicNumbers ? toArabicNumbers(formatted) : formatted;
  }
  
  // تنسيق التاريخ والوقت
  static String formatDateTime(DateTime dateTime, {bool useArabicNumbers = true}) {
    final formatter = DateFormat('dd/MM/yyyy - HH:mm');
    String formatted = formatter.format(dateTime);
    return useArabicNumbers ? toArabicNumbers(formatted) : formatted;
  }
  
  // تحويل String إلى double مع دعم الأرقام العربية
  static double parseDouble(String value) {
    if (value.isEmpty) return 0.0;
    String normalized = toEnglishNumbers(value).replaceAll(',', '');
    return double.tryParse(normalized) ?? 0.0;
  }
  
  // تحويل String إلى int مع دعم الأرقام العربية
  static int parseInt(String value) {
    if (value.isEmpty) return 0;
    String normalized = toEnglishNumbers(value).replaceAll(',', '');
    return int.tryParse(normalized) ?? 0;
  }
  
  // توليد رقم فاتورة تلقائي
  static String generateInvoiceNumber(int lastId) {
    final now = DateTime.now();
    final year = now.year.toString().substring(2);
    final month = now.month.toString().padLeft(2, '0');
    final id = (lastId + 1).toString().padLeft(4, '0');
    return 'INV-$year$month-$id';
  }
  
  // التحقق من صحة البريد الإلكتروني
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
  
  // التحقق من صحة رقم الهاتف
  static bool isValidPhone(String phone) {
    String normalized = toEnglishNumbers(phone);
    return RegExp(r'^07[3-9]\d{8}$').hasMatch(normalized);
  }
  
  // اختصار النص
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
  
  // حساب النسبة المئوية
  static double calculatePercentage(double part, double total) {
    if (total == 0) return 0;
    return (part / total) * 100;
  }
  
  // تحويل الحالة إلى نص عربي
  static String getStatusText(String status) {
    switch (status) {
      case 'paid':
        return 'مسددة';
      case 'unpaid':
        return 'غير مسددة';
      case 'partial':
        return 'مسددة جزئياً';
      default:
        return 'غير معروف';
    }
  }
  
  // الحصول على لون الحالة
  static String getStatusColor(String status) {
    switch (status) {
      case 'paid':
        return 'success';
      case 'unpaid':
        return 'danger';
      case 'partial':
        return 'warning';
      default:
        return 'grey';
    }
  }
  
  // عرض رسالة نجاح
  static void showSuccessMessage(String message) {
    // سيتم استخدامها مع SnackBar في الواجهة
  }
  
  // عرض رسالة خطأ
  static void showErrorMessage(String message) {
    // سيتم استخدامها مع SnackBar في الواجهة
  }
}
