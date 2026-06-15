class OrderModel {
  final String id;
  final String orderId;
  final String status;
  final double totalAmount;
  final String paymentStatus;
  final List<OrderItem> items;
  final ShippingAddress shippingAddress;
  final DateTime createdAt;
  final String awb;
  final String courierPartner;
  final String trackingUrl;
  final double subtotal;
  final double totalGst;
  final double deliveryFee;
  final String? deliveryOtp;
  final String? gstNumber;
  final String? panNumber;
  final bool isBusinessPurchase;
  final String invoiceType;

  OrderModel({
    required this.id,
    required this.orderId,
    required this.status,
    required this.totalAmount,
    required this.paymentStatus,
    required this.items,
    required this.shippingAddress,
    required this.createdAt,
    this.awb = '',
    this.courierPartner = '',
    this.trackingUrl = '',
    this.subtotal = 0.0,
    this.totalGst = 0.0,
    this.deliveryFee = 0.0,
    this.deliveryOtp,
    this.gstNumber,
    this.panNumber,
    this.isBusinessPurchase = false,
    this.invoiceType = 'RETAIL',
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['_id'] ?? '',
      orderId: json['orderId'] ?? '',
      status: json['status'] ?? 'CREATED',
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      paymentStatus: json['paymentStatus'] ?? 'PENDING',
      items: (json['items'] as List?)?.map((i) => OrderItem.fromJson(i)).toList() ?? [],
      shippingAddress: ShippingAddress.fromJson(json['shippingAddress'] ?? {}),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      awb: json['awb'] ?? '',
      courierPartner: json['courierPartner'] ?? '',
      trackingUrl: json['trackingUrl'] ?? '',
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      totalGst: (json['totalGst'] ?? 0).toDouble(),
      deliveryFee: (json['deliveryFee'] ?? json['deliveryCharge'] ?? 0).toDouble(),
      deliveryOtp: json['deliveryOtp'],
      gstNumber: json['gstNumber'],
      panNumber: json['panNumber'],
      isBusinessPurchase: json['isBusinessPurchase'] ?? false,
      invoiceType: json['invoiceType'] ?? 'RETAIL',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'orderId': orderId,
      'status': status,
      'totalAmount': totalAmount,
      'paymentStatus': paymentStatus,
      'items': items.map((i) => i.toJson()).toList(),
      'shippingAddress': shippingAddress.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'awb': awb,
      'courierPartner': courierPartner,
      'trackingUrl': trackingUrl,
      'subtotal': subtotal,
      'totalGst': totalGst,
      'deliveryFee': deliveryFee,
      'deliveryOtp': deliveryOtp,
      'gstNumber': gstNumber,
      'panNumber': panNumber,
      'isBusinessPurchase': isBusinessPurchase,
      'invoiceType': invoiceType,
    };
  }
}

class OrderItem {
  final String productId;
  final String name;
  final int quantity;
  final double price;
  final String image;
  final double gstAmount;
  final double finalPrice;

  OrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
    required this.image,
    this.gstAmount = 0.0,
    this.finalPrice = 0.0,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['product'] ?? '',
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      image: json['image'] ?? '',
      gstAmount: (json['gstAmount'] ?? 0).toDouble(),
      finalPrice: (json['finalPrice'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': productId,
      'name': name,
      'quantity': quantity,
      'price': price,
      'image': image,
      'gstAmount': gstAmount,
      'finalPrice': finalPrice,
    };
  }
}

class ShippingAddress {
  final String street;
  final String city;
  final String state;
  final String zipCode;

  ShippingAddress({
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
  });

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress(
      street: json['street'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      zipCode: json['zipCode'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'zipCode': zipCode,
    };
  }

  @override
  String toString() {
    return '$street, $city, $state, $zipCode';
  }
}
