import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/invoice_model.dart';
import '../utils/helpers.dart';
import '../utils/constants.dart';
import '../services/print_service.dart';

class InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const InvoiceCard({
    super.key,
    required this.invoice,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => onTap(),
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'تعديل',
          ),
          SlidableAction(
            onPressed: (context) => _showMoreOptions(context),
            backgroundColor: AppConstants.accentColor,
            foregroundColor: Colors.white,
            icon: Icons.more_horiz,
            label: 'المزيد',
          ),
          SlidableAction(
            onPressed: (context) => onDelete(),
            backgroundColor: AppConstants.dangerColor,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'حذف',
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getStatusColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.receipt,
            color: _getStatusColor(),
          ),
        ),
        title: Text(
          invoice.invoiceNumber,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              Helpers.formatDate(invoice.date),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'المجموع: ${Helpers.formatCurrency(invoice.grandTotal)}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 12),
                Text(
                  'المتبقي: ${Helpers.formatCurrency(invoice.remainingBalance)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: invoice.remainingBalance > 0 ? AppConstants.dangerColor : AppConstants.successColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getStatusColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            Helpers.getStatusText(invoice.status),
            style: TextStyle(
              color: _getStatusColor(),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.print, color: AppConstants.primaryColor),
              title: const Text('طباعة الفاتورة'),
              onTap: () async {
                Navigator.pop(context);
                await PrintService.printInvoice(invoice);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: AppConstants.primaryColor),
              title: const Text('مشاركة الفاتورة'),
              onTap: () async {
                Navigator.pop(context);
                await PrintService.shareInvoiceAsText(invoice);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: AppConstants.primaryColor),
              title: const Text('تعديل الفاتورة'),
              onTap: () {
                Navigator.pop(context);
                onTap();
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (invoice.status) {
      case 'paid':
        return AppConstants.successColor;
      case 'unpaid':
        return AppConstants.dangerColor;
      case 'partial':
        return AppConstants.accentColor;
      default:
        return Colors.grey;
    }
  }
}(
            onPressed: (context) => onTap(),
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'تعديل',
          ),
          SlidableAction(
            onPressed: (context) => onDelete(),
            backgroundColor: AppConstants.dangerColor,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'حذف',
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getStatusColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.receipt,
            color: _getStatusColor(),
          ),
        ),
        title: Text(
          invoice.invoiceNumber,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              Helpers.formatDate(invoice.date),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
                          Row(
              children: [
                Text(
                  'المجموع: ${Helpers.formatCurrency(invoice.grandTotal)}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 12),
                Text(
                  'المتبقي: ${Helpers.formatCurrency(invoice.remainingBalance)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: invoice.remainingBalance > 0 ? AppConstants.dangerColor : AppConstants.successColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getStatusColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            Helpers.getStatusText(invoice.status),
            style: TextStyle(
              color: _getStatusColor(),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (invoice.status) {
      case 'paid':
        return AppConstants.successColor;
      case 'unpaid':
        return AppConstants.dangerColor;
      case 'partial':
        return AppConstants.accentColor;
      default:
        return Colors.grey;
    }
  }
}
