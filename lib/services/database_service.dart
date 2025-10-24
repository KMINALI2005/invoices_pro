import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/invoice_model.dart';
import '../models/product_model.dart';
import '../models/invoice_item_model.dart';
import '../utils/constants.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(AppConstants.databaseName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // جدول المنتجات
    await db.execute('''
      CREATE TABLE ${AppConstants.productsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // جدول الفواتير
    await db.execute('''
      CREATE TABLE ${AppConstants.invoicesTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT NOT NULL UNIQUE,
        customer_name TEXT NOT NULL,
        date TEXT NOT NULL,
        previous_balance REAL NOT NULL DEFAULT 0,
        amount_received REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // جدول عناصر الفاتورة
    await db.execute('''
      CREATE TABLE ${AppConstants.invoiceItemsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        price REAL NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (invoice_id) REFERENCES ${AppConstants.invoicesTable} (id) ON DELETE CASCADE
      )
    ''');

    // إنشاء indexes لتحسين الأداء
    await db.execute('''
      CREATE INDEX idx_customer_name ON ${AppConstants.invoicesTable}(customer_name)
    ''');

    await db.execute('''
      CREATE INDEX idx_invoice_date ON ${AppConstants.invoicesTable}(date)
    ''');

    await db.execute('''
      CREATE INDEX idx_invoice_items ON ${AppConstants.invoiceItemsTable}(invoice_id)
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // للإصدارات المستقبلية
  }

  // ================ عمليات المنتجات ================

  Future<Product> createProduct(Product product) async {
    final db = await database;
    final id = await db.insert(AppConstants.productsTable, product.toMap());
    return product.copyWith(id: id);
  }

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final result = await db.query(
      AppConstants.productsTable,
      orderBy: 'name ASC',
    );
    return result.map((map) => Product.fromMap(map)).toList();
  }

  Future<Product?> getProductById(int id) async {
    final db = await database;
    final maps = await db.query(
      AppConstants.productsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Product>> searchProducts(String query) async {
    final db = await database;
    final result = await db.query(
      AppConstants.productsTable,
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'name ASC',
    );
    return result.map((map) => Product.fromMap(map)).toList();
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    return await db.update(
      AppConstants.productsTable,
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete(
      AppConstants.productsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ================ عمليات الفواتير ================

  Future<Invoice> createInvoice(Invoice invoice) async {
    final db = await database;
    
    // إدراج الفاتورة
    final invoiceId = await db.insert(
      AppConstants.invoicesTable,
      invoice.toMap(),
    );
    
    // إدراج عناصر الفاتورة
    for (var item in invoice.items) {
      await db.insert(
        AppConstants.invoiceItemsTable,
        item.copyWith(invoiceId: invoiceId).toMap(),
      );
    }
    
    return invoice.copyWith(id: invoiceId);
  }

  Future<List<Invoice>> getAllInvoices() async {
    final db = await database;
    final result = await db.query(
      AppConstants.invoicesTable,
      orderBy: 'date DESC, created_at DESC',
    );
    
    List<Invoice> invoices = [];
    for (var map in result) {
      final invoice = Invoice.fromMap(map);
      invoice.items = await getInvoiceItems(invoice.id!);
      invoices.add(invoice);
    }
    
    return invoices;
  }

  Future<Invoice?> getInvoiceById(int id) async {
    final db = await database;
    final maps = await db.query(
      AppConstants.invoicesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      final invoice = Invoice.fromMap(maps.first);
      invoice.items = await getInvoiceItems(id);
      return invoice;
    }
    return null;
  }

  Future<List<InvoiceItem>> getInvoiceItems(int invoiceId) async {
    final db = await database;
    final result = await db.query(
      AppConstants.invoiceItemsTable,
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
      orderBy: 'id ASC',
    );
    return result.map((map) => InvoiceItem.fromMap(map)).toList();
  }

  Future<List<Invoice>> getInvoicesByCustomer(String customerName) async {
    final db = await database;
    final result = await db.query(
      AppConstants.invoicesTable,
      where: 'customer_name = ?',
      whereArgs: [customerName],
      orderBy: 'date DESC',
    );
    
    List<Invoice> invoices = [];
    for (var map in result) {
      final invoice = Invoice.fromMap(map);
      invoice.items = await getInvoiceItems(invoice.id!);
      invoices.add(invoice);
    }
    
    return invoices;
  }

  Future<List<Invoice>> searchInvoices(String query) async {
    final db = await database;
    final result = await db.query(
      AppConstants.invoicesTable,
      where: 'customer_name LIKE ? OR invoice_number LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'date DESC',
    );
    
    List<Invoice> invoices = [];
    for (var map in result) {
      final invoice = Invoice.fromMap(map);
      invoice.items = await getInvoiceItems(invoice.id!);
      invoices.add(invoice);
    }
    
    return invoices;
  }

  Future<List<Invoice>> getInvoicesByStatus(String status) async {
    final db = await database;
    final result = await db.query(
      AppConstants.invoicesTable,
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'date DESC',
    );
    
    List<Invoice> invoices = [];
    for (var map in result) {
      final invoice = Invoice.fromMap(map);
      invoice.items = await getInvoiceItems(invoice.id!);
      invoices.add(invoice);
    }
    
    return invoices;
  }

  Future<int> updateInvoice(Invoice invoice) async {
    final db = await database;
    
    // تحديث الفاتورة
    final result = await db.update(
      AppConstants.invoicesTable,
      invoice.toMap(),
      where: 'id = ?',
      whereArgs: [invoice.id],
    );
    
    // حذف العناصر القديمة
    await db.delete(
      AppConstants.invoiceItemsTable,
      where: 'invoice_id = ?',
      whereArgs: [invoice.id],
    );
    
    // إدراج العناصر الجديدة
    for (var item in invoice.items) {
      await db.insert(
        AppConstants.invoiceItemsTable,
        item.copyWith(invoiceId: invoice.id).toMap(),
      );
    }
    
    return result;
  }

  Future<int> deleteInvoice(int id) async {
    final db = await database;
    
    // حذف العناصر أولاً
    await db.delete(
      AppConstants.invoiceItemsTable,
      where: 'invoice_id = ?',
      whereArgs: [id],
    );
    
    // ثم حذف الفاتورة
    return await db.delete(
      AppConstants.invoicesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ================ إحصائيات ================

  Future<List<String>> getAllCustomerNames() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT DISTINCT customer_name 
      FROM ${AppConstants.invoicesTable} 
      ORDER BY customer_name ASC
    ''');
    return result.map((map) => map['customer_name'] as String).toList();
  }

  Future<double> getCustomerTotalBalance(String customerName) async {
    final invoices = await getInvoicesByCustomer(customerName);
    return invoices.fold(0.0, (sum, invoice) => sum + invoice.remainingBalance);
  }

  Future<Map<String, dynamic>> getStatistics() async {
    final db = await database;
    
    // عدد الزبائن
    final customersResult = await db.rawQuery('''
      SELECT COUNT(DISTINCT customer_name) as count 
      FROM ${AppConstants.invoicesTable}
    ''');
    final customersCount = customersResult.first['count'] as int;
    
    // عدد الفواتير
    final invoicesResult = await db.rawQuery('''
      SELECT COUNT(*) as count 
      FROM ${AppConstants.invoicesTable}
    ''');
    final invoicesCount = invoicesResult.first['count'] as int;
    
    // إجمالي المبالغ
    final allInvoices = await getAllInvoices();
    final totalAmount = allInvoices.fold(0.0, (sum, inv) => sum + inv.grandTotal);
    final totalReceived = allInvoices.fold(0.0, (sum, inv) => sum + inv.amountReceived);
    final totalRemaining = allInvoices.fold(0.0, (sum, inv) => sum + inv.remainingBalance);
    
    // عدد المنتجات
    final productsResult = await db.rawQuery('''
      SELECT COUNT(*) as count 
      FROM ${AppConstants.productsTable}
    ''');
    final productsCount = productsResult.first['count'] as int;
    
    return {
      'customersCount': customersCount,
      'invoicesCount': invoicesCount,
      'productsCount': productsCount,
      'totalAmount': totalAmount,
      'totalReceived': totalReceived,
      'totalRemaining': totalRemaining,
    };
  }

  Future<int> getLastInvoiceId() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT MAX(id) as maxId FROM ${AppConstants.invoicesTable}
    ''');
    final maxId = result.first['maxId'];
    return maxId != null ? maxId as int : 0;
  }

  // ================ عمليات عامة ================

  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
