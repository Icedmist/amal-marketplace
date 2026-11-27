double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('${value ?? ''}') ?? 0;
}

int _asInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse('${value ?? ''}') ?? 0;
}

class PlaceOrderItem {
  const PlaceOrderItem({
    required this.productId,
    required this.quantity,
    this.color,
    this.size,
  });

  final String productId;
  final int quantity;
  final String? color;
  final String? size;

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'quantity': quantity,
    'color': color,
    'size': size,
  };
}

class PlaceOrderRequest {
  const PlaceOrderRequest({
    required this.items,
    required this.name,
    required this.phone,
    required this.street,
    required this.city,
    required this.state,
    required this.method,
    required this.payment,
    this.email,
    this.landmark,
    this.note,
    this.couponCode,
  });

  final List<PlaceOrderItem> items;
  final String name;
  final String phone;
  final String? email;
  final String street;
  final String city;
  final String state;
  final String? landmark;
  final String? note;
  final String method;
  final String payment;
  final String? couponCode;

  Map<String, dynamic> toJson() => {
    'items': items.map((item) => item.toJson()).toList(),
    'name': name,
    'phone': phone,
    'email': email,
    'street': street,
    'city': city,
    'state': state,
    'landmark': landmark,
    'note': note,
    'method': method,
    'payment': payment,
    'couponCode': couponCode,
  };
}

class PlacedOrderLine {
  const PlacedOrderLine({
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  final String name;
  final int quantity;
  final double unitPrice;

  factory PlacedOrderLine.fromJson(Map<String, dynamic> json) {
    return PlacedOrderLine(
      name: '${json['name'] ?? 'Item'}',
      quantity: _asInt(json['quantity']),
      unitPrice: _asDouble(json['unit_price']),
    );
  }
}

class PlacedOrder {
  const PlacedOrder({
    required this.reference,
    required this.subtotal,
    required this.discount,
    required this.deliveryFee,
    required this.total,
    required this.lines,
  });

  final String reference;
  final double subtotal;
  final double discount;
  final double deliveryFee;
  final double total;
  final List<PlacedOrderLine> lines;

  factory PlacedOrder.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lines'];
    return PlacedOrder(
      reference: '${json['reference'] ?? ''}',
      subtotal: _asDouble(json['subtotal']),
      discount: _asDouble(json['discount']),
      deliveryFee: _asDouble(json['deliveryFee']),
      total: _asDouble(json['total']),
      lines: rawLines is List
          ? rawLines
                .whereType<Map>()
                .map(
                  (line) => PlacedOrderLine.fromJson(
                    Map<String, dynamic>.from(line),
                  ),
                )
                .toList()
          : const [],
    );
  }
}

class OrderLine {
  const OrderLine({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.imageUrl,
    this.color,
    this.size,
  });

  final String productName;
  final int quantity;
  final double unitPrice;
  final String? imageUrl;
  final String? color;
  final String? size;

  double get lineTotal => unitPrice * quantity;

  String get variantLabel =>
      [color, size].whereType<String>().where((v) => v.trim().isNotEmpty).join(' · ');

  factory OrderLine.fromJson(Map<String, dynamic> json) {
    return OrderLine(
      productName: '${json['product_name'] ?? 'Item'}',
      quantity: _asInt(json['quantity']),
      unitPrice: _asDouble(json['unit_price']),
      imageUrl: json['image_url'] as String?,
      color: json['color'] as String?,
      size: json['size'] as String?,
    );
  }
}

class OrderDetail {
  const OrderDetail({
    required this.id,
    required this.reference,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.deliveryAddress,
    required this.deliveryCity,
    required this.deliveryState,
    required this.deliveryMethod,
    required this.deliveryFee,
    required this.deliveryNote,
    required this.estimatedDelivery,
    required this.subtotal,
    required this.discount,
    required this.couponCode,
    required this.total,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.createdAt,
    required this.items,
  });

  final String id;
  final String reference;
  final String customerName;
  final String customerPhone;
  final String? customerEmail;
  final String deliveryAddress;
  final String deliveryCity;
  final String deliveryState;
  final String deliveryMethod;
  final double deliveryFee;
  final String? deliveryNote;
  final String? estimatedDelivery;
  final double subtotal;
  final double discount;
  final String? couponCode;
  final double total;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final DateTime? createdAt;
  final List<OrderLine> items;

  bool get isPaid => paymentStatus == 'paid';

  bool get canPayOnline => paymentMethod == 'paystack' && !isPaid;

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    final rawItems = json['order_items'];
    return OrderDetail(
      id: '${json['id'] ?? ''}',
      reference: '${json['reference'] ?? ''}',
      customerName: '${json['customer_name'] ?? ''}',
      customerPhone: '${json['customer_phone'] ?? ''}',
      customerEmail: json['customer_email'] as String?,
      deliveryAddress: '${json['delivery_address'] ?? ''}',
      deliveryCity: '${json['delivery_city'] ?? ''}',
      deliveryState: '${json['delivery_state'] ?? ''}',
      deliveryMethod: '${json['delivery_method'] ?? 'standard'}',
      deliveryFee: _asDouble(json['delivery_fee']),
      deliveryNote: json['delivery_note'] as String?,
      estimatedDelivery: json['estimated_delivery'] as String?,
      subtotal: _asDouble(json['subtotal']),
      discount: _asDouble(json['discount']),
      couponCode: json['coupon_code'] as String?,
      total: _asDouble(json['total']),
      status: '${json['status'] ?? 'pending'}',
      paymentMethod: '${json['payment_method'] ?? 'whatsapp'}',
      paymentStatus: '${json['payment_status'] ?? 'pending'}',
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse('${json['created_at']}'),
      items: rawItems is List
          ? rawItems
                .whereType<Map>()
                .map((item) => OrderLine.fromJson(Map<String, dynamic>.from(item)))
                .toList()
          : const [],
    );
  }
}

class OrderSummary {
  const OrderSummary({
    required this.reference,
    required this.customerName,
    required this.total,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.createdAt,
  });

  final String reference;
  final String customerName;
  final double total;
  final String status;
  final String paymentStatus;
  final String paymentMethod;
  final DateTime? createdAt;

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    return OrderSummary(
      reference: '${json['reference'] ?? ''}',
      customerName: '${json['customer_name'] ?? ''}',
      total: _asDouble(json['total']),
      status: '${json['status'] ?? 'pending'}',
      paymentStatus: '${json['payment_status'] ?? 'pending'}',
      paymentMethod: '${json['payment_method'] ?? 'whatsapp'}',
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse('${json['created_at']}'),
    );
  }
}

const orderStatusFlow = [
  'pending',
  'confirmed',
  'processing',
  'shipped',
  'out_for_delivery',
  'delivered',
];

const statusLabels = <String, String>{
  'pending': 'Pending',
  'confirmed': 'Confirmed',
  'processing': 'Processing',
  'shipped': 'Shipped',
  'out_for_delivery': 'Out for Delivery',
  'delivered': 'Delivered',
  'cancelled': 'Cancelled',
  'paid': 'Paid',
  'failed': 'Failed',
  'refunded': 'Refunded',
};

String statusLabel(String value) => statusLabels[value] ?? value;

String paymentMethodLabel(String value) {
  switch (value) {
    case 'paystack':
      return 'Pay online (Paystack)';
    case 'cash_on_delivery':
      return 'Cash on delivery';
    default:
      return 'WhatsApp / bank transfer';
  }
}

String deliveryMethodLabel(String value) {
  switch (value) {
    case 'express':
      return 'Express delivery';
    case 'pickup':
      return 'Pick up at shop';
    default:
      return 'Standard delivery';
  }
}
