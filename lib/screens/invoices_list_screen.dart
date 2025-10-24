import 'package:flutter/material.dart';
import '../models/invoice_model.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'create_invoice_screen.dart';
import '../widgets/invoice_card.dart';
import '../widgets/stats_card.dart';

class InvoicesListScreen extends StatefulWidget {
  const InvoicesListScreen({super.key});

  @override
  State<InvoicesListScreen> createState() => _InvoicesListScreenState();
}

class _InvoicesListScreenState extends State<InvoicesListScreen> {
  final DatabaseService _dbService = DatabaseService.instance;
  List<Invoice> _allInvoices = [];
  List<Invoice> _filteredInvoices = [];
  Map<String, List<Invoice>> _groupedInvoices = {};
  String _selectedFilter = 'all'; // all, unpaid, paid
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() => _isLoading = true);
    try {
      final invoices = await _dbService.getAllInvoices();
      setState(() {
        _allInvoices = invoices;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل الفواتير: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    List<Invoice> filtered = List.from(_allInvoices);

    // فلترة حسب الحالة
    if (_selectedFilter == 'unpaid') {
      filtered = filtered.where((inv) => inv.status == 'unpaid').toList();
    } else if (_selectedFilter == 'paid') {
      filtered = filtered.where((inv) => inv.status == 'paid').toList();
    }

    // البحث
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      filtered = filtered.where((inv) {
        return inv.customerName.contains(query) ||
            inv.invoiceNumber.contains(query);
      }).toList();
    }

    // التجميع حسب اسم الزبون
    _groupedInvoices = {};
    for (var invoice in filtered) {
      if (!_groupedInvoices.containsKey(invoice.customerName)) {
        _groupedInvoices[invoice.customerName] = [];
      }
      _groupedInvoices[invoice.customerName]!.add(invoice);
    }

    _filteredInvoices = filtered;
  }

  Future<void> _deleteInvoice(Invoice invoice) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف فاتورة ${invoice.invoiceNumber}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppConstants.dangerColor),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _dbService.deleteInvoice(invoice.id!);
        _loadInvoices();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف الفاتورة بنجاح')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ في حذف الفاتورة: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الفواتير'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInvoices,
          ),
        ],
      ),
      body: Column(
        children: [
          // الإحصائيات
          _buildStatistics(),

          // شريط البحث والفلترة
          _buildSearchAndFilter(),

          // قائمة الفواتير
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredInvoices.isEmpty
                    ? _buildEmptyState()
                    : _buildInvoicesList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateInvoiceScreen(),
            ),
          );
          if (result == true) {
            _loadInvoices();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('فاتورة جديدة'),
      ),
    );
  }

  Widget _buildStatistics() {
    final totalInvoices = _allInvoices.length;
    final totalAmount = _allInvoices.fold(0.0, (sum, inv) => sum + inv.grandTotal);
    final totalRemaining = _allInvoices.fold(0.0, (sum, inv) => sum + inv.remainingBalance);
    final customersCount = _allInvoices.map((inv) => inv.customerName).toSet().length;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: StatsCard(
              title: 'عدد الزبائن',
              value: Helpers.toArabicNumbers(customersCount.toString()),
              icon: Icons.people,
              color: AppConstants.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatsCard(
              title: 'عدد الفواتير',
              value: Helpers.toArabicNumbers(totalInvoices.toString()),
              icon: Icons.receipt_long,
              color: AppConstants.accentColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatsCard(
              title: 'المتبقي',
              value: Helpers.formatCurrency(totalRemaining),
              icon: Icons.account_balance_wallet,
              color: totalRemaining > 0 ? AppConstants.dangerColor : AppConstants.successColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // حقل البحث
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'بحث بالاسم أو رقم الفاتورة...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              setState(() {
                _applyFilters();
              });
            },
          ),
          const SizedBox(height: 12),
          // أزرار الفلترة
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'الكل'),
                const SizedBox(width: 8),
                _buildFilterChip('unpaid', 'غير مسددة'),
                const SizedBox(width: 8),
                _buildFilterChip('paid', 'مسددة'),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
          _applyFilters();
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: AppConstants.primaryColor.withOpacity(0.2),
      checkmarkColor: AppConstants.primaryColor,
    );
  }

  Widget _buildInvoicesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _groupedInvoices.length,
      itemBuilder: (context, index) {
        final customerName = _groupedInvoices.keys.elementAt(index);
        final invoices = _groupedInvoices[customerName]!;
        final totalBalance = invoices.fold(0.0, (sum, inv) => sum + inv.remainingBalance);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: AppConstants.primaryColor,
              child: Text(
                customerName[0],
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              customerName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              '${Helpers.toArabicNumbers(invoices.length.toString())} فاتورة - المتبقي: ${Helpers.formatCurrency(totalBalance)}',
              style: TextStyle(
                color: totalBalance > 0 ? AppConstants.dangerColor : AppConstants.successColor,
              ),
            ),
            children: invoices.map((invoice) {
              return InvoiceCard(
                invoice: invoice,
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateInvoiceScreen(invoice: invoice),
                    ),
                  );
                  if (result == true) {
                    _loadInvoices();
                  }
                },
                onDelete: () => _deleteInvoice(invoice),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد فواتير',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط على الزر أدناه لإنشاء فاتورة جديدة',
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
