import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:ojas_user/features/home/domain/models/product_model.dart';

class UrlHelper {
  /// Converts any string into a clean, SEO-friendly URL slug.
  /// E.g. "Pooja & Spiritual Decor" -> "pooja-and-spiritual-decor"
  /// E.g. "Silver Plated Shankh Chakra Deepak Set with Gift Box - Pack of 1"
  ///      -> "silver-plated-shankh-chakra-deepak-set-with-gift-box-pack-of-1"
  static String slugify(String? text) {
    if (text == null) return '';
    String str = text.trim().toLowerCase();
    if (str.isEmpty) return '';

    // Replace '&' with 'and'
    str = str.replaceAll('&', 'and');

    // Replace non-alphanumeric characters with '-'
    str = str.replaceAll(RegExp(r'[^a-z0-9]+'), '-');

    // Remove multiple consecutive hyphens and trim leading/trailing hyphens
    str = str.replaceAll(RegExp(r'-+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');

    return str;
  }

  /// Checks if an original name matches a given URL slug.
  static bool matchesSlug(String? originalName, String? slug) {
    if (originalName == null || slug == null) return false;
    final origSlug = slugify(originalName);
    final targetSlug = slugify(slug);

    if (origSlug == targetSlug) return true;

    // Also match when 'and' or dashes are omitted
    final cleanOrig = origSlug.replaceAll('-', '').replaceAll('and', '');
    final cleanTarget = targetSlug.replaceAll('-', '').replaceAll('and', '');
    return cleanOrig.isNotEmpty && cleanOrig == cleanTarget;
  }

  /// Constructs category / subcategory URL path.
  /// E.g.
  /// categoryUrl("Pooja & Spiritual Decor") -> "/shop/pooja-and-spiritual-decor"
  /// categoryUrl("Pooja & Spiritual Decor", "Pooja Thali Sets") -> "/shop/pooja-and-spiritual-decor/pooja-thali-sets"
  static String categoryUrl(String? categoryName, [String? subCategoryName]) {
    if (categoryName == null || categoryName.trim().isEmpty || categoryName == 'All') {
      return '/shop';
    }

    final catSlug = slugify(categoryName);
    if (subCategoryName == null || subCategoryName.trim().isEmpty || subCategoryName == 'All') {
      return '/shop/$catSlug';
    }

    final subSlug = slugify(subCategoryName);
    return '/shop/$catSlug/$subSlug';
  }

  /// Constructs product-wise URL path incorporating category and subcategory.
  /// E.g.
  /// /product/pooja-and-spiritual-decor/pooja-thali-sets/silver-plated-shankh-chakra-deepak-set
  static String productUrl(dynamic product, {String? refCode}) {
    String? category;
    String? subCategory;
    String? slugOrName;
    String? id;
    String? resellerCode;

    if (product is ProductModel) {
      id = product.id;
      category = product.category;
      subCategory = product.subCategory;
      slugOrName = (product.slug != null && product.slug!.isNotEmpty)
          ? product.slug
          : product.name;
      resellerCode = product.resellerCode;
    } else if (product is Map) {
      id = (product['_id'] ?? product['id'] ?? '').toString();
      final cat = product['category'];
      if (cat is Map) {
        category = cat['name']?.toString();
      } else if (cat is String) {
        category = cat;
      }
      subCategory = product['subCategory']?.toString();
      slugOrName = product['slug']?.toString();
      if (slugOrName == null || slugOrName.isEmpty) {
        slugOrName = product['name']?.toString() ?? product['title']?.toString();
      }
      resellerCode = product['resellerCode']?.toString();
    } else {
      id = product?.toString() ?? '';
    }

    final String finalProductSlug = slugify(slugOrName).isNotEmpty
        ? slugify(slugOrName)
        : (id.isNotEmpty ? id : 'item');

    final String catSlug = (category != null && category != 'All')
        ? slugify(category)
        : '';
    final String subCatSlug = (subCategory != null && subCategory != 'All')
        ? slugify(subCategory)
        : '';

    String path = '/product';
    if (catSlug.isNotEmpty) {
      path += '/$catSlug';
      if (subCatSlug.isNotEmpty) {
        path += '/$subCatSlug';
      }
    }
    path += '/$finalProductSlug';

    final effectiveRef = (refCode != null && refCode.isNotEmpty)
        ? refCode
        : resellerCode;

    if (effectiveRef != null && effectiveRef.isNotEmpty) {
      path += '?ref=$effectiveRef';
    }

    return path;
  }

  /// Updates browser URL bar without reloading the page.
  static void updateBrowserUrl(String path, {bool pushState = true}) {
    if (!kIsWeb) return;
    try {
      final currentPath = html.window.location.pathname ?? '';
      final currentSearch = html.window.location.search ?? '';
      final fullCurrent = '$currentPath$currentSearch';

      if (fullCurrent == path) return;

      if (pushState) {
        html.window.history.pushState(null, '', path);
      } else {
        html.window.history.replaceState(null, '', path);
      }
    } catch (_) {}
  }
}
