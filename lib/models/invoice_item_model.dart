class InvoiceItem {
  int? id;
  int? invoiceId;
  String productName;
  int quantity;
  double price;
  String? notes;
  DateTime createdAt;

  InvoiceItem({
    this.id,
    this.invoiceId,
    required this.productName,
    required this.quantity,
    required this.price,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // حساب المجموع
  double get total => quantity * price;

  // تحويل من Map إلى Object
  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map['id'] as int?,
      invoiceId: map['invoice_id'] as int?,
      productName: map['product_name'] as String,
      quantity: map['quantity'] as int,
      price: (map['price'] as num).toDouble(),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // تحويل من Object إلى Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'product_name': productName,
      'quantity': quantity,
      'price': price,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'product_name': productName,
      'quantity': quantity,
      'price': price,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // إنشاء من JSON
  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      id: json['id'] as int?,
      invoiceId: json['invoice_id'] as int?,
      productName: json['product_name'] as String,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // نسخ مع تعديل
  InvoiceItem copyWith({
    int? id,
    int? invoiceId,
    String? productName,
    int? quantity,
    double? price,
    String? notes,
    DateTime? createdAt,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'InvoiceItem{id: $id, productName: $productName, quantity: $quantity, price: $price, total: $total}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InvoiceItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
