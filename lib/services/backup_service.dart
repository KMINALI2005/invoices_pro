import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../models/invoice_model.dart';
import '../models/product_model.dart';
import '../services/database_service.dart';

class BackupService {
  static final DatabaseService _dbService = DatabaseService.instance;

  // تصدير البيانات إلى JSON
  static Future<Map<String, dynamic>> exportToJson() async {
    final invoices = await _dbService.getAllInvoices();
    final products = await _dbService.getAllProducts();

    return {
      'version': '1.0',
      'export_date': DateTime.now().toIso8601String(),
      'invoices': invoices.map((inv) => inv.toJson()).toList(),
      'products': products.map((prod) => prod.toJson()).toList(),
    };
  }

  // حفظ النسخة الاحتياطية في ملف
  static Future<String?> saveBackupToFile() async {
    try {
      final data = await exportToJson();
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'invoices_backup_$timestamp.json';
      final filePath = '${directory.path}/$fileName';
      
      final file = File(filePath);
      await file.writeAsString(jsonString);
      
      return filePath;
    } catch (e) {
      print('Error saving backup: $e');
      return null;
    }
  }

  // مشاركة النسخة الاحتياطية
  static Future<bool> shareBackup() async {
    try {
      final filePath = await saveBackupToFile();
      if (filePath != null) {
        await Share.shareXFiles(
          [XFile(filePath)],
          subject: 'نسخة احتياطية - فواتير برو',
          text: 'نسخة احتياطية من بيانات فواتير برو',
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Error sharing backup: $e');
      return false;
    }
  }

  // استيراد النسخة الاحتياطية
  static Future<bool> importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final data = json.decode(jsonString) as Map<String, dynamic>;

        // التحقق من صحة البيانات
        if (!data.containsKey('invoices') || !data.containsKey('products')) {
          return false;
        }

        // استيراد المنتجات
        final productsData = data['products'] as List<dynamic>;
        for (var productJson in productsData) {
          final product = Product.fromJson(productJson as Map<String, dynamic>);
          await _dbService.createProduct(product.copyWith(id: null));
        }

        // استيراد الفواتير
        final invoicesData = data['invoices'] as List<dynamic>;
        for (var invoiceJson in invoicesData) {
          final invoice = Invoice.fromJson(invoiceJson as Map<String, dynamic>);
          await _dbService.createInvoice(invoice.copyWith(id: null));
        }

        return true;
      }
      return false;
    } catch (e) {
      print('Error importing backup: $e');
      return false;
    }
  }

  // تصدير إلى CSV
  static Future<String?> exportToCSV() async {
    try {
      final invoices = await _dbService.getAllInvoices();
      
      final csvBuffer = StringBuffer();
      csvBuffer.writeln('رقم الفاتورة,اسم الزبون,التاريخ,المجموع الكلي,المبلغ الواصل,المتبقي,الحالة');
      
      for (var invoice in invoices) {
        csvBuffer.writeln(
          '${invoice.invoiceNumber},${invoice.customerName},${invoice.date.toIso8601String()},'
          '${invoice.grandTotal},${invoice.amountReceived},${invoice.remainingBalance},${invoice.status}'
        );
      }
      
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'invoices_export_$timestamp.csv';
      final filePath = '${directory.path}/$fileName';
      
      final file = File(filePath);
      await file.writeAsString(csvBuffer.toString());
      
      return filePath;
    } catch (e) {
      print('Error exporting to CSV: $e');
      return null;
    }
  }

  // مشاركة CSV
  static Future<bool> shareCSV() async {
    try {
      final filePath = await exportToCSV();
      if (filePath != null) {
        await Share.shareXFiles(
          [XFile(filePath)],
          subject: 'تقرير الفواتير - CSV',
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Error sharing CSV: $e');
      return false;
    }
  }
}
