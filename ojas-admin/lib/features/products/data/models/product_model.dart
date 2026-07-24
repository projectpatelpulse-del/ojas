import 'dart:convert';
import 'package:ojas_admin/core/services/api_service.dart';

class ProductAttributes {
  final bool size;
  final bool color;
  final bool material;

  ProductAttributes({
    this.size = false,
    this.color = false,
    this.material = false,
  });

  factory ProductAttributes.fromJson(Map<String, dynamic>? map) {
    if (map == null) return ProductAttributes();
    return ProductAttributes(
      size: map['size'] ?? false,
      color: map['color'] ?? false,
      material: map['material'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'size': size,
      'color': color,
      'material': material,
    };
  }
}

class ProductVariation {
  final String id;
  final String? size;
  final String? color;
  final String? material;
  final double price;
  final int stock;
  final String? sku;

  ProductVariation({
    required this.id,
    this.size,
    this.color,
    this.material,
    required this.price,
    required this.stock,
    this.sku,
  });

  factory ProductVariation.fromJson(Map<String, dynamic> map) {
    return ProductVariation(
      id: map['_id'] ?? '',
      size: map['size'],
      color: map['color'],
      material: map['material'],
      price: _toDouble(map['price']),
      stock: _toInt(map['stock']),
      sku: map['sku'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'size': size,
      'color': color,
      'material': material,
      'price': price,
      'stock': stock,
      'sku': sku,
    };
  }
}

class VendorModel {
  final String id;
  final String name;
  final String email;
  final String? mobile;
  final String? shopName;

  VendorModel({
    required this.id,
    required this.name,
    required this.email,
    this.mobile,
    this.shopName,
  });

  factory VendorModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return VendorModel(id: '', name: '', email: '');
    return VendorModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      mobile: json['mobile'],
      shopName: json['shopName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'mobile': mobile,
      'shopName': shopName,
    };
  }
}

class ProductDimensions {
  final double length;
  final double width;
  final double height;

  ProductDimensions({
    this.length = 0,
    this.width = 0,
    this.height = 0,
  });

  factory ProductDimensions.fromJson(Map<String, dynamic>? map) {
    if (map == null) return ProductDimensions();
    return ProductDimensions(
      length: _toDouble(map['length']),
      width: _toDouble(map['width']),
      height: _toDouble(map['height']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'length': length,
      'width': width,
      'height': height,
    };
  }
}

class ProductSpecification {
  final String id;
  final String key;
  final String value;

  ProductSpecification({
    required this.id,
    required this.key,
    required this.value,
  });

  factory ProductSpecification.fromJson(Map<String, dynamic> map) {
    return ProductSpecification(
      id: map['_id'] ?? '',
      key: map['key'] ?? '',
      value: map['value'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'key': key,
      'value': value,
    };
  }
}

class ProductModel {
  final String id;
  final String name;
  final String title;
  final double price;
  final double? oldPrice;
  final double discountPrice;
  final String image;
  final List<String> images;
  final int discount;
  final bool isFlashDeal;
  final int stock;

  final double? gst;
  final String? hsnCode;
  final int moq;

  // Rich metadata fields
  final String? shortDescription;
  final String? fullDescription;
  final String brand;
  final String category;
  final String? subCategory;
  final double? weight;
  final double? length;
  final double? width;
  final double? height;
  final String? youtubeLink;
  final List<ProductSpecification>? specifications;
  final List<String>? tags;
  
  // New aligned schema fields
  final ProductAttributes attributes;
  final List<ProductVariation> variations;
  final ProductDimensions dimensions;
  final VendorModel? vendor;
  
  final int lowStockThreshold;
  final bool trackQuantity;
  final bool requiresShipping;
  final String? seoTitle;
  final String? seoDescription;
  final String? slug;
  final String status;
  final String visibility;
  final double moqDiscount;
  final String moqTiers;
  final List<String> showOnPages;
  
  // Pricing calculation fields
  final double? originalPrice;
  final double? commissionPercent;
  final double? commissionAmount;
  final double? sellingPrice;

  final List<String> relatedProducts;

  ProductModel({
    required this.id,
    required this.name,
    required this.title,
    required this.price,
    this.oldPrice,
    required this.discountPrice,
    required this.image,
    this.images = const [],
    this.discount = 0,
    this.isFlashDeal = false,
    required this.stock,
    this.relatedProducts = const [],
    this.gst,
    this.hsnCode,
    this.moq = 1,
    this.shortDescription,
    this.fullDescription,
    required this.brand,
    required this.category,
    this.subCategory,
    this.weight,
    this.length,
    this.width,
    this.height,
    this.youtubeLink,
    this.specifications,
    this.tags,
    required this.attributes,
    required this.variations,
    required this.dimensions,
    this.vendor,
    this.lowStockThreshold = 5,
    this.trackQuantity = true,
    this.requiresShipping = true,
    this.seoTitle,
    this.seoDescription,
    this.slug,
    this.status = 'Draft',
    this.visibility = 'Public',
    this.moqDiscount = 0,
    this.moqTiers = '',
    this.showOnPages = const ['Shop'],
    this.originalPrice,
    this.commissionPercent,
    this.commissionAmount,
    this.sellingPrice,
  });

  factory ProductModel.fromJson(Map<String, dynamic> p) {
    double discountPrice = _toDouble(p['discountPrice']);
    double price = discountPrice > 0 ? discountPrice : _toDouble(p['price'] ?? 0);
    double oldPrice = _toDouble(p['price']);
    int disc = oldPrice > 0 && oldPrice > price ? _toInt(((oldPrice - price) / oldPrice) * 100) : 0;

    String? imageUrl;
    List<String> images = [];
    
    // Support gallery key mapping, fallback to images, and fallback to image url
    if (p['gallery'] != null && (p['gallery'] as List).isNotEmpty) {
      images = (p['gallery'] as List).map((e) => ApiService.formatImageUrl(e.toString())).toList();
    } else if (p['images'] != null && (p['images'] as List).isNotEmpty) {
      images = (p['images'] as List).map((e) => ApiService.formatImageUrl(e.toString())).toList();
    }

    if (images.isNotEmpty) {
      imageUrl = images[0];
    } else if (p['image'] != null) {
      imageUrl = ApiService.formatImageUrl(p['image'].toString());
      images = [imageUrl];
    }

    List<ProductSpecification>? specs;
    if (p['specs'] != null) {
      try {
        specs = (p['specs'] as List).map((e) => ProductSpecification.fromJson(Map<String, dynamic>.from(e))).toList();
      } catch (e) {
        try {
          final decoded = jsonDecode(p['specs']);
          specs = (decoded as List).map((e) => ProductSpecification.fromJson(Map<String, dynamic>.from(e))).toList();
        } catch (_) {}
      }
    }

    List<ProductVariation> variations = [];
    if (p['variations'] != null) {
      try {
        variations = (p['variations'] as List).map((e) => ProductVariation.fromJson(Map<String, dynamic>.from(e))).toList();
      } catch (_) {}
    }

    ProductAttributes attributes = ProductAttributes.fromJson(
      p['attributes'] != null ? Map<String, dynamic>.from(p['attributes']) : null
    );

    ProductDimensions dimensions = ProductDimensions.fromJson(
      p['dimensions'] != null 
          ? Map<String, dynamic>.from(p['dimensions']) 
          : Map<String, dynamic>.from(p)
    );

    VendorModel? vendor;
    if (p['user'] != null) {
      try {
        vendor = VendorModel.fromJson(Map<String, dynamic>.from(p['user']));
      } catch (_) {}
    }

    return ProductModel(
      id: p['_id'] ?? '',
      name: p['name'] ?? 'Product',
      title: p['title'] ?? p['name'] ?? 'Product',
      price: price,
      oldPrice: oldPrice > price ? oldPrice : null,
      discountPrice: discountPrice,
      image: imageUrl ?? '',
      images: images,
      discount: disc,
      isFlashDeal: disc > 20,
      stock: _toInt(p['stock'] ?? 0),
      relatedProducts: (p['relatedProducts'] as List?)?.map((e) => e.toString()).toList() ?? [],
      gst: _toDouble(p['gst']),
      hsnCode: p['hsnCode'],
      moq: _toInt(p['moq'] ?? 1),
      shortDescription: p['shortDescription'],
      fullDescription: p['description'], // Notice key is 'description' in backend Product schema
      brand: p['brand'] ?? '',
      category: p['category'] ?? '',
      subCategory: p['subCategory'],
      weight: _toDouble(p['weight']),
      length: dimensions.length,
      width: dimensions.width,
      height: dimensions.height,
      youtubeLink: p['youtubeLink'],
      specifications: specs,
      tags: (p['tags'] as List?)?.map((e) => e.toString()).toList(),
      attributes: attributes,
      variations: variations,
      dimensions: dimensions,
      vendor: vendor,
      lowStockThreshold: _toInt(p['lowStockThreshold'] ?? 5),
      trackQuantity: p['trackQuantity'] ?? true,
      requiresShipping: p['requiresShipping'] ?? true,
      seoTitle: p['seoTitle'],
      seoDescription: p['seoDescription'],
      slug: p['slug'],
      status: p['status'] ?? 'Draft',
      visibility: p['visibility'] ?? 'Public',
      moqDiscount: _toDouble(p['moqDiscount']),
      moqTiers: p['moqTiers']?.toString() ?? '',
      showOnPages: (p['showOnPages'] as List?)?.map((e) => e.toString()).toList() ?? ['Shop'],
      originalPrice: _toDouble(p['originalPrice']),
      commissionPercent: _toDouble(p['commissionPercent']),
      commissionAmount: _toDouble(p['commissionAmount']),
      sellingPrice: _toDouble(p['sellingPrice']),
    );
  }
}

double _toDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? 0.0;
  return 0.0;
}

int _toInt(dynamic val) {
  if (val == null) return 0;
  if (val is num) return val.toInt();
  if (val is String) {
    final doubleVal = double.tryParse(val);
    if (doubleVal != null) return doubleVal.toInt();
    return int.tryParse(val) ?? 0;
  }
  return 0;
}
