import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/invoice_model.dart';
import '../utils/helpers.dart';
import '../utils/constants.dart';

class PrintService {
  static Future<void> printInvoice(Invoice invoice) async {
    final pdf = await _generateInvoicePDF(invoice);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static Future<void> shareInvoiceAsText(Invoice invoice) async {
    final text = _generateInvoiceText(invoice);
    await Share.share(
      text,
      subject: 'فاتورة ${invoice.invoiceNumber}',
    );
  }

  static Future<pw.Document> _generateInvoicePDF(Invoice invoice) async {
    final pdf = pw.Document();

    // تحميل خط عربي (في التطبيق الحقيقي يجب إضافة الخط من assets)
    // final arabicFont = await PdfGoogleFonts.cairoRegular();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // رأس الفاتورة
                _buildPDFHeader(invoice),
                pw.SizedBox(height: 20),
                pw.Divider(thickness: 2),
                pw.SizedBox(height: 20),

                // معلومات الزبون
                _buildPDFCustomerInfo(invoice),
                pw.SizedBox(height: 20),

                // جدول المنتجات
                _buildPDFItemsTable(invoice),
                pw.SizedBox(height: 20),

                // الحسابات
                _buildPDFCalculations(invoice),
                
                pw.Spacer(),
                
                // التذييل
                _buildPDFFooter(),
              ],
            ),
          );
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildPDFHeader(Invoice invoice) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              AppConstants.companyName,
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 5),
            pw.Text(AppConstants.companyPhone, style: const pw.TextStyle(fontSize: 12)),
            pw.Text(AppConstants.companyAddress, style: const pw.TextStyle(fontSize: 12)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey300,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text(
                'فاتورة',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text('رقم: ${invoice.invoiceNumber}', style: const pw.TextStyle(fontSize: 12)),
            pw.Text('التاريخ: ${Helpers.formatDate(invoice.date)}', style: const pw.TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildPDFCustomerInfo(Invoice invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'معلومات الزبون',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          pw.Text('الاسم: ${invoice.customerName}', style: const pw.TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  static pw.Widget _buildPDFItemsTable(Invoice invoice) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey),
      children: [
        // رأس الجدول
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableCell('ت', isHeader: true),
            _buildTableCell('اسم المنتج', isHeader: true),
            _buildTableCell('الكمية', isHeader: true),
            _buildTableCell('السعر', isHeader: true),
            _buildTableCell('المجموع', isHeader: true),
          ],
        ),
        // الصفوف
        ...invoice.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return pw.TableRow(
            children: [
              _buildTableCell((index + 1).toString()),
              _buildTableCell(item.productName),
              _buildTableCell(item.quantity.toString()),
              _buildTableCell(Helpers.formatCurrency(item.price)),
              _buildTableCell(Helpers.formatCurrency(item.total)),
            ],
          );
        }).toList(),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 11,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildPDFCalculations(Invoice invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          _buildCalculationRow('مجموع المنتجات:', Helpers.formatCurrency(invoice.itemsTotal)),
          pw.SizedBox(height: 5),
          _buildCalculationRow('الحساب السابق:', Helpers.formatCurrency(invoice.previousBalance)),
          pw.Divider(thickness: 1),
          _buildCalculationRow(
            'المجموع الكلي:',
            Helpers.formatCurrency(invoice.grandTotal),
            isBold: true,
          ),
          pw.SizedBox(height: 5),
          _buildCalculationRow('المبلغ الواصل:', Helpers.formatCurrency(invoice.amountReceived)),
          pw.Divider(thickness: 2),
          _buildCalculationRow(
            'المتبقي:',
            Helpers.formatCurrency(invoice.remainingBalance),
            isBold: true,
            fontSize: 14,
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCalculationRow(String label, String value,
      {bool isBold = false, double fontSize = 12}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildPDFFooter() {
    return pw.Column(
      children: [
        pw.Divider(thickness: 1),
        pw.SizedBox(height: 10),
        pw.Text(
          'شكراً لتعاملكم معنا',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'تم إنشاء هذه الفاتورة بواسطة ${AppConstants.appName}',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
        ),
      ],
    );
  }

  // توليد نص الفاتورة للمشاركة
  static String _generateInvoiceText(Invoice invoice) {
    final buffer = StringBuffer();
    
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📄 ${AppConstants.appName}');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln();
    buffer.writeln('🏢 ${AppConstants.companyName}');
    buffer.writeln('📱 ${AppConstants.companyPhone}');
    buffer.writeln('📍 ${AppConstants.companyAddress}');
    buffer.writeln();
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📋 رقم الفاتورة: ${invoice.invoiceNumber}');
    buffer.writeln('📅 التاريخ: ${Helpers.formatDate(invoice.date)}');
    buffer.writeln('👤 الزبون: ${invoice.customerName}');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln();
    buffer.writeln('📦 المنتجات:');
    buffer.writeln();
    
    for (var i = 0; i < invoice.items.length; i++) {
      final item = invoice.items[i];
      buffer.writeln('${i + 1}. ${item.productName}');
      buffer.writeln('   الكمية: ${Helpers.toArabicNumbers(item.quantity.toString())}');
      buffer.writeln('   السعر: ${Helpers.formatCurrency(item.price)} دينار');
      buffer.writeln('   المجموع: ${Helpers.formatCurrency(item.total)} دينار');
      if (item.notes != null && item.notes!.isNotEmpty) {
        buffer.writeln('   ملاحظة: ${item.notes}');
      }
      buffer.writeln();
    }
    
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('💰 الحسابات:');
    buffer.writeln();
    buffer.writeln('مجموع المنتجات: ${Helpers.formatCurrency(invoice.itemsTotal)} دينار');
    buffer.writeln('الحساب السابق: ${Helpers.formatCurrency(invoice.previousBalance)} دينار');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('المجموع الكلي: ${Helpers.formatCurrency(invoice.grandTotal)} دينار');
    buffer.writeln('المبلغ الواصل: ${Helpers.formatCurrency(invoice.amountReceived)} دينار');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('✅ المتبقي: ${Helpers.formatCurrency(invoice.remainingBalance)} دينار');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln();
    
    if (invoice.notes != null && invoice.notes!.isNotEmpty) {
      buffer.writeln('📝 ملاحظات: ${invoice.notes}');
      buffer.writeln();
    }
    
    buffer.writeln('شكراً لتعاملكم معنا 🙏');
    buffer.writeln();
    buffer.writeln('تم إنشاء هذه الفاتورة بواسطة ${AppConstants.appName}');
    
    return buffer.toString();
  }

  // طباعة كشف حساب الزبون
  static Future<void> printCustomerStatement(
    String customerName,
    List<Invoice> invoices,
  ) async {
    final pdf = pw.Document();

    final totalAmount = invoices.fold(0.0, (sum, inv) => sum + inv.grandTotal);
    final totalReceived = invoices.fold(0.0, (sum, inv) => sum + inv.amountReceived);
    final totalRemaining = invoices.fold(0.0, (sum, inv) => sum + inv.remainingBalance);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // رأس الكشف
                pw.Text(
                  'كشف حساب',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                pw.Text('الزبون: $customerName', style: const pw.TextStyle(fontSize: 14)),
                pw.Text('التاريخ: ${Helpers.formatDate(DateTime.now())}', style: const pw.TextStyle(fontSize: 12)),
                pw.SizedBox(height: 20),
                pw.Divider(thickness: 2),
                pw.SizedBox(height: 20),

                // جدول الفواتير
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        _buildTableCell('رقم الفاتورة', isHeader: true),
                        _buildTableCell('التاريخ', isHeader: true),
                        _buildTableCell('المجموع', isHeader: true),
                        _buildTableCell('المستلم', isHeader: true),
                        _buildTableCell('المتبقي', isHeader: true),
                      ],
                    ),
                    ...invoices.map((invoice) {
                      return pw.TableRow(
                        children: [
                          _buildTableCell(invoice.invoiceNumber),
                          _buildTableCell(Helpers.formatDate(invoice.date)),
                          _buildTableCell(Helpers.formatCurrency(invoice.grandTotal)),
                          _buildTableCell(Helpers.formatCurrency(invoice.amountReceived)),
                          _buildTableCell(Helpers.formatCurrency(invoice.remainingBalance)),
                        ],
                      );
                    }).toList(),
                  ],
                ),

                pw.SizedBox(height: 20),

                // الملخص
                pw.Container(
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    children: [
                      _buildCalculationRow('عدد الفواتير:', invoices.length.toString()),
                      pw.Divider(),
                      _buildCalculationRow('إجمالي المبالغ:', Helpers.formatCurrency(totalAmount)),
                      _buildCalculationRow('المبالغ المستلمة:', Helpers.formatCurrency(totalReceived)),
                      pw.Divider(thickness: 2),
                      _buildCalculationRow(
                        'المتبقي الإجمالي:',
                        Helpers.formatCurrency(totalRemaining),
                        isBold: true,
                        fontSize: 14,
                      ),
                    ],
                  ),
                ),

                pw.Spacer(),
                _buildPDFFooter(),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
