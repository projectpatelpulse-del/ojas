import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
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
  static String productUrl(dynamic product, {String? refCode, dynamic variation}) {
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

    if (variation != null) {
      String? varIdentifier;
      if (variation is ProductVariation) {
        varIdentifier = (variation.title != null && variation.title!.trim().isNotEmpty)
            ? variation.title
            : (variation.modelName ?? variation.sku);
      } else if (variation is Map) {
        varIdentifier = (variation['title'] != null && variation['title'].toString().trim().isNotEmpty)
            ? variation['title'].toString()
            : (variation['modelName'] ?? variation['size'] ?? variation['sku'])?.toString();
      } else if (variation is String && variation.trim().isNotEmpty) {
        varIdentifier = variation;
      }
      if (varIdentifier != null && varIdentifier.trim().isNotEmpty) {
        final s = slugify(varIdentifier);
        if (s.isNotEmpty) {
          path += '/$s';
        }
      }
    }

    final effectiveRef = (refCode != null && refCode.isNotEmpty)
        ? refCode
        : resellerCode;

    if (effectiveRef != null && effectiveRef.isNotEmpty) {
      path += '?ref=$effectiveRef';
    }

    return path;
  }

  /// Updates browser URL bar without reloading the page.
  static void updateBrowserUrl(String path, {bool pushState = false}) {
    if (!kIsWeb) return;
    try {
      SystemNavigator.routeInformationUpdated(
        uri: Uri.parse(path),
        replace: !pushState,
      );
    } catch (_) {
      try {
        final currentState = html.window.history.state;
        if (pushState) {
          html.window.history.pushState(currentState, '', path);
        } else {
          html.window.history.replaceState(currentState, '', path);
        }
      } catch (_) {}
    }
  }
}
