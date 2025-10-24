import 'package:flutter/material.dart';
import '../models/invoice_model.dart';
import '../services/database_service.dart';
import '../services/print_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class AuditingScreen extends StatefulWidget {
  const AuditingScreen({super.key});

  @override
  State<AuditingScreen> createState() => _AuditingScreenState();
}

class _AuditingScreenState extends State<AuditingScreen> {
  final DatabaseService _dbService = DatabaseService.instance;
  Map<String, List<Invoice>> _customerInvoices = {};
  Map<String, double> _customerBalances = {};
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredCustomers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final allInvoices = await _dbService.getAllInvoices();
      
      // تجميع الفواتير حسب الزبون
      Map<String, List<Invoice>> groupedInvoices = {};
      Map<String, double> balances = {};
      
      for (var invoice in allInvoices) {
        if (!groupedInvoices.containsKey(invoice.customerName)) {
          groupedInvoices[invoice.customerName] = [];
          balances[invoice.customerName] = 0.0;
        }
        groupedInvoices[invoice.customerName]!.add(invoice);
        balances[invoice.customerName] = 
            balances[invoice.customerName]! + invoice.remainingBalance;
      }

      setState(() {
        _customerInvoices = groupedInvoices;
        _customerBalances = balances;
        _filteredCustomers = groupedInvoices.keys.toList()
          ..sort((a, b) => b.compareTo(a));
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل البيانات: $e')),
        );
      }
    }
  }

  void _searchCustomers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCustomers = _customerInvoices.keys.toList()
          ..sort((a, b) => b.compareTo(a));
      } else {
        _filteredCustomers = _customerInvoices.keys
            .where((customer) => customer.contains(query))
            .toList()
          ..sort((a, b) => b.compareTo(a));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مراجعة الحسابات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // الإحصائيات الإجمالية
          _buildOverallStatistics(),

          // شريط البحث
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'بحث عن زبون...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _searchCustomers,
            ),
          ),

          // قائمة الزبائن
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCustomers.isEmpty
                    ? _buildEmptyState()
                    : _buildCustomersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallStatistics() {
    final totalCustomers = _customerInvoices.length;
    final totalInvoices = _customerInvoices.values
        .fold(0, (sum, invoices) => sum + invoices.length);
    final totalBalance = _customerBalances.values.fold(0.0, (sum, balance) => sum + balance);
    final customersWithDebt = _customerBalances.values
        .where((balance) => balance > 0)
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'عدد الزبائن',
                  Helpers.toArabicNumbers(totalCustomers.toString()),
                  Icons.people,
                  AppConstants.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'إجمالي الفواتير',
                  Helpers.toArabicNumbers(totalInvoices.toString()),
                  Icons.receipt_long,
                  AppConstants.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'المتبقي الكلي',
                  Helpers.formatCurrency(totalBalance),
                  Icons.account_balance_wallet,
                  totalBalance > 0 ? AppConstants.dangerColor : AppConstants.successColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'زبائن بذمة',
                  Helpers.toArabicNumbers(customersWithDebt.toString()),
                  Icons.warning_amber,
                  AppConstants.dangerColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomersList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredCustomers.length,
      itemBuilder: (context, index) {
        final customerName = _filteredCustomers[index];
        final invoices = _customerInvoices[customerName]!;
        final balance = _customerBalances[customerName]!;
        final lastInvoiceDate = invoices.map((inv) => inv.date).reduce(
            (a, b) => a.isAfter(b) ? a : b);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: balance > 0
                  ? AppConstants.dangerColor.withOpacity(0.1)
                  : AppConstants.successColor.withOpacity(0.1),
              child: Icon(
                balance > 0 ? Icons.trending_up : Icons.check_circle,
                color: balance > 0 ? AppConstants.dangerColor : AppConstants.successColor,
              ),
            ),
            title: Text(
              customerName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'عدد الفواتير: ${Helpers.toArabicNumbers(invoices.length.toString())}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'آخر فاتورة: ${Helpers.formatDate(lastInvoiceDate)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Helpers.formatCurrency(balance),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: balance > 0 ? AppConstants.dangerColor : AppConstants.successColor,
                  ),
                ),
                Text(
                  balance > 0 ? 'متبقي' : 'مسدد',
                  style: TextStyle(
                    fontSize: 11,
                    color: balance > 0 ? AppConstants.dangerColor : AppConstants.successColor,
                  ),
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showCustomerDetails(customerName, invoices),
                            icon: const Icon(Icons.visibility),
                            label: const Text('عرض التفاصيل'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _printCustomerStatement(customerName, invoices),
                            icon: const Icon(Icons.print),
                            label: const Text('طباعة كشف'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppConstants.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'الفواتير (${Helpers.toArabicNumbers(invoices.length.toString())}):',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...invoices.map((invoice) => _buildInvoiceRow(invoice)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInvoiceRow(Invoice invoice) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              invoice.invoiceNumber,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Text(
            Helpers.formatDate(invoice.date),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(width: 12),
          Text(
            Helpers.formatCurrency(invoice.remainingBalance),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: invoice.remainingBalance > 0
                  ? AppConstants.dangerColor
                  : AppConstants.successColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomerDetails(String customerName, List<Invoice> invoices) {
    final totalAmount = invoices.fold(0.0, (sum, inv) => sum + inv.grandTotal);
    final totalReceived = invoices.fold(0.0, (sum, inv) => sum + inv.amountReceived);
    final totalRemaining = invoices.fold(0.0, (sum, inv) => sum + inv.remainingBalance);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(customerName),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('عدد الفواتير', Helpers.toArabicNumbers(invoices.length.toString())),
              const Divider(),
              _buildDetailRow('إجمالي المبالغ', Helpers.formatCurrency(totalAmount)),
              _buildDetailRow('المبالغ المستلمة', Helpers.formatCurrency(totalReceived)),
              _buildDetailRow(
                'المتبقي',
                Helpers.formatCurrency(totalRemaining),
                color: totalRemaining > 0 ? AppConstants.dangerColor : AppConstants.successColor,
              ),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'الفواتير:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...invoices.map((inv) => Card(
                    child: ListTile(
                      dense: true,
                      title: Text(inv.invoiceNumber, style: const TextStyle(fontSize: 13)),
                      subtitle: Text(Helpers.formatDate(inv.date), style: const TextStyle(fontSize: 11)),
                      trailing: Text(
                        Helpers.formatCurrency(inv.remainingBalance),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: inv.remainingBalance > 0
                              ? AppConstants.dangerColor
                              : AppConstants.successColor,
                        ),
                      ),
                    ),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _printCustomerStatement(String customerName, List<Invoice> invoices) {
    PrintService.printCustomerStatement(customerName, invoices).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('جاري الطباعة...')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في الطباعة: $error')),
      );
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد بيانات',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'قم بإنشاء فواتير لعرض التقارير',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
