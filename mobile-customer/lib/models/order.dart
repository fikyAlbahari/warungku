class OrderItem {
  const OrderItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.qty,
    required this.subtotal,
  });

  final int? productId;
  final String productName;
  final int price;
  final int qty;
  final int subtotal;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['product_id'] == null ? null : _int(json['product_id']),
      productName: (json['product_name'] ?? '').toString(),
      price: _int(json['price']),
      qty: _int(json['qty']),
      subtotal: _int(json['subtotal']),
    );
  }
}

class Order {
  const Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.total,
    required this.itemCount,
    this.subtotal = 0,
    this.shippingCost = 0,
    this.paymentMethod,
    this.isPaid = false,
    this.shippingAddress,
    this.note,
    this.createdAt,
    this.items = const [],
  });

  final int id;
  final String orderNumber;
  final String status;
  final int total;
  final int itemCount;
  final int subtotal;
  final int shippingCost;
  final String? paymentMethod;
  final bool isPaid;
  final String? shippingAddress;
  final String? note;
  final DateTime? createdAt;
  final List<OrderItem> items;

  bool get isPending => status == 'pending';
  bool get isCancelled => status == 'dibatalkan';

  factory Order.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];

    return Order(
      id: _int(json['id']),
      orderNumber: (json['order_number'] ?? '-').toString(),
      status: (json['status'] ?? 'pending').toString(),
      total: _int(json['total']),
      itemCount: _int(json['item_count']),
      subtotal: _int(json['subtotal']),
      shippingCost: _int(json['shipping_cost']),
      paymentMethod: json['payment_method']?.toString(),
      isPaid: json['is_paid'] == true,
      shippingAddress: json['shipping_address']?.toString(),
      note: json['note']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      items: rawItems is List
          ? rawItems
                .whereType<Map<String, dynamic>>()
                .map(OrderItem.fromJson)
                .toList()
          : const [],
    );
  }
}

int _int(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is String) return double.tryParse(value)?.round() ?? 0;
  return 0;
}
