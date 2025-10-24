import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/invoice_model.dart';
import '../models/invoice_item_model.dart';
import '../models/product_model.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class CreateInvoiceScreen extends StatefulWidget {
  final Invoice? invoice;

  const CreateInvoiceScreen({super.key, this.invoice});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _dbService = DatabaseService.instance;

  // Controllers
  final _customerNameController = TextEditingController();
  final _previousBalanceController = TextEditingController();
  final _amountReceivedController = TextEditingController();
  final _notesController = TextEditingController();
  final _productNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _itemNotesController = TextEditingController();

  // Focus Nodes
  final _quantityFocus = FocusNode();
  final _priceFocus = FocusNode();
  final _itemNotesFocus = FocusNode();

  // Data
  List<InvoiceItem> _items = [];
  List<String> _customerSuggestions = [];
  List<Product> _products = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    if (widget.invoice != null) {
      _isEditMode = true;
      _loadInvoiceData();
    }
  }

  Future<void> _loadData() async {
    final customers = await _dbService.getAllCustomerNames();
    final products = await _dbService.getAllProducts();
    setState(() {
      _customerSuggestions = customers;
      _products = products;
    });
  }

  void _loadInvoiceData() {
    final invoice = widget.invoice!;
    _customerNameController.text = invoice.customerName;
    _previousBalanceController.text = invoice.previousBalance.toString();
    _amountReceivedController.text = invoice.amountReceived.toString();
    _notesController.text = invoice.notes ?? '';
    _selectedDate = invoice.date;
    _items = List.from(invoice.items);
  }

  Future<void> _saveInvoice() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب إضافة منتج واحد على الأقل')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final lastId = await _dbService.getLastInvoiceId();
      final invoiceNumber = _isEditMode
          ? widget.invoice!.invoiceNumber
          : Helpers.generateInvoiceNumber(lastId);

      final invoice = Invoice(
        id: _isEditMode ? widget.invoice!.id : null,
        invoiceNumber: invoiceNumber,
        customerName: _customerNameController.text.trim(),
        date: _selectedDate,
        items: _items,
        previousBalance: Helpers.parseDouble(_previousBalanceController.text),
        amountReceived: Helpers.parseDouble(_amountReceivedController.text),
        status: 'unpaid',
        notes: _notesController.text.trim(),
      );

      // تحديث الحالة تلقائياً
      invoice.status = invoice.autoStatus;

      if (_isEditMode) {
        await _dbService.updateInvoice(invoice);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث الفاتورة بنجاح')),
          );
        }
      } else {
        await _dbService.createInvoice(invoice);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إنشاء الفاتورة بنجاح')),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addItem() {
    if (_productNameController.text.isEmpty ||
        _quantityController.text.isEmpty ||
        _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع حقول المنتج')),
      );
      return;
    }

    final item = InvoiceItem(
      productName: _productNameController.text.trim(),
      quantity: Helpers.parseInt(_quantityController.text),
      price: Helpers.parseDouble(_priceController.text),
      notes: _itemNotesController.text.trim(),
    );

    setState(() {
      _items.add(item);
      _productNameController.clear();
      _quantityController.text = '1';
      _priceController.clear();
      _itemNotesController.clear();
    });

    _productNameController.requestFocus();
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  double get _itemsTotal {
    return _items.fold(0.0, (sum, item) => sum + item.total);
  }

  double get _grandTotal {
    return _itemsTotal + Helpers.parseDouble(_previousBalanceController.text);
  }

  double get _remainingBalance {
    return _grandTotal - Helpers.parseDouble(_amountReceivedController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'تعديل الفاتورة' : 'فاتورة جديدة'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveInvoice,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // معلومات الزبون والتاريخ
            _buildCustomerSection(),
            const SizedBox(height: 16),

            // إضافة منتج
            _buildAddProductSection(),
            const SizedBox(height: 16),

            // قائمة المنتجات
            _buildItemsList(),
            const SizedBox(height: 16),

            // الحسابات
            _buildCalculationsSection(),
            const SizedBox(height: 16),

            // ملاحظات
            _buildNotesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'معلومات الزبون',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Autocomplete<String>(
              initialValue: TextEditingValue(text: _customerNameController.text),
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<String>.empty();
                }
                return _customerSuggestions.where((suggestion) {
                  return suggestion.contains(textEditingValue.text);
                });
              },
              onSelected: (selection) {
                _customerNameController.text = selection;
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                _customerNameController.text = controller.text;
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: 'اسم الزبون',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال اسم الزبون';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                );
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'تاريخ الفاتورة',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(Helpers.formatDate(_selectedDate)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddProductSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'إضافة منتج',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add_circle),
                  label: const Text('إضافة'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppConstants.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Autocomplete<Product>(
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<Product>.empty();
                }
                return _products.where((product) {
                  return product.name.contains(textEditingValue.text);
                });
              },
              displayStringForOption: (product) => product.name,
              onSelected: (product) {
                _productNameController.text = product.name;
                _priceController.text = product.price.toString();
                _quantityFocus.requestFocus();
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                _productNameController.text = controller.text;
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: 'اسم المنتج',
                    prefixIcon: Icon(Icons.inventory_2),
                  ),
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _quantityFocus.requestFocus(),
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _quantityController,
                    focusNode: _quantityFocus,
                    decoration: const InputDecoration(
                      labelText: 'الكمية',
                      prefixIcon: Icon(Icons.numbers),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => _priceFocus.requestFocus(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _priceController,
                    focusNode: _priceFocus,
                    decoration: const InputDecoration(
                      labelText: 'السعر',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _addItem(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _itemNotesController,
              focusNode: _itemNotesFocus,
              decoration: const InputDecoration(
                labelText: 'ملاحظات المنتج (اختياري)',
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 2,
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    if (_items.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'لم يتم إضافة منتجات بعد',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'المنتجات (${Helpers.toArabicNumbers(_items.length.toString())})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = _items[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
                  child: Text(
                    Helpers.toArabicNumbers((index + 1).toString()),
                    style: const TextStyle(
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  item.productName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الكمية: ${Helpers.toArabicNumbers(item.quantity.toString())} × ${Helpers.formatCurrency(item.price)}',
                    ),
                    if (item.notes != null && item.notes!.isNotEmpty)
                      Text(
                        item.notes!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Helpers.formatCurrency(item.total),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      color: AppConstants.dangerColor,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _removeItem(index),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الحسابات',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildCalculationRow(
              'مجموع المنتجات',
              Helpers.formatCurrency(_itemsTotal),
              AppConstants.primaryColor,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _previousBalanceController,
              decoration: const InputDecoration(
                labelText: 'الحساب السابق',
                prefixIcon: Icon(Icons.history),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            const Divider(),
            _buildCalculationRow(
              'المجموع الكلي',
              Helpers.formatCurrency(_grandTotal),
              AppConstants.accentColor,
              isBold: true,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountReceivedController,
              decoration: const InputDecoration(
                labelText: 'المبلغ الواصل',
                prefixIcon: Icon(Icons.payments),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            const Divider(),
            _buildCalculationRow(
              'المتبقي',
              Helpers.formatCurrency(_remainingBalance),
              _remainingBalance > 0 ? AppConstants.dangerColor : AppConstants.successColor,
              isBold: true,
              isLarge: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculationRow(String label, String value, Color color,
      {bool isBold = false, bool isLarge = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isLarge ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isLarge ? 18 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ملاحظات عامة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'أضف ملاحظات للفاتورة (اختياري)...',
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _previousBalanceController.dispose();
    _amountReceivedController.dispose();
    _notesController.dispose();
    _productNameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _itemNotesController.dispose();
    _quantityFocus.dispose();
    _priceFocus.dispose();
    _itemNotesFocus.dispose();
    super.dispose();
  }
}
