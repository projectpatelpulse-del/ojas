import 'dart:convert';
import 'dart:io' as io;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ojas_vendor/core/constants/app_colors.dart';
import 'package:ojas_vendor/core/widgets/vendor_topbar.dart';
import 'package:ojas_vendor/core/services/service_locator.dart';
import 'package:ojas_vendor/features/products/data/services/product_service.dart';
import 'package:ojas_vendor/features/categories/data/services/category_service.dart';

import '../../../../core/services/api_service.dart';

part 'add_product_helpers.dart';
part 'add_product_basic_info.dart';
part 'add_product_pricing_media.dart';
part 'add_product_variants_specs.dart';

class AddProductPage extends StatefulWidget {
  final dynamic product;
  const AddProductPage({super.key, this.product});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  // Basic Info
  final _productNameCtrl = TextEditingController();
  final _shortDescCtrl = TextEditingController();
  final _fullDescCtrl = TextEditingController();
  String _prevFullDescText = '';
  final _brandCtrl = TextEditingController();
  String? _selectedCategory;
  String? _selectedSubCategory;
  List<dynamic> _categories = [];
  List<dynamic> _subCategories = [];

  final _regularPriceCtrl = TextEditingController();
  final _discountedPriceCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();
  final _hsnCodeCtrl = TextEditingController();
  final _moqCtrl = TextEditingController();
  final _moqDiscountCtrl = TextEditingController();
  final _moqTiersCtrl = TextEditingController();

  // Media
  final _youtubeCtrl = TextEditingController();
  XFile? _mainImage;
  String? _mainImageUrl;
  final List<XFile> _galleryImages = [];
  final List<String> _galleryUrls = [];

  // Status & Visibility
  String _productStatus = 'Draft';
  String _visibility = 'Public';

  final _skuCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _lowStockCtrl = TextEditingController();
  bool _trackQuantity = true;

  // Shipping
  final _weightCtrl = TextEditingController();
  final _lengthCtrl = TextEditingController();
  final _widthCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  bool _requiresShipping = true;

  // SEO
  final _seoTitleCtrl = TextEditingController();
  final _seoDescCtrl = TextEditingController();
  final _slugCtrl = TextEditingController();

  // Specs
  final List<TextEditingController> _specKeyCtrls = [];
  final List<TextEditingController> _specValCtrls = [];

  // Variations
  bool _sizeAttr = false;
  bool _colorAttr = false;
  bool _materialAttr = false;
  bool _weightAttr = false;
  final _sizeOptionsCtrl = TextEditingController();
  final _colorOptionsCtrl = TextEditingController();
  final _materialOptionsCtrl = TextEditingController();
  final _weightOptionsCtrl = TextEditingController();
  bool _syncVariationDetails = false;
  bool _autoBulletMode = true;
  List<Map<String, dynamic>> _variations = [];
  final List<TextEditingController> _variationPriceCtrls = [];
  final List<TextEditingController> _variationOldPriceCtrls = [];
  final List<TextEditingController> _variationStockCtrls = [];
  final List<TextEditingController> _variationTitleCtrls = [];
  final List<TextEditingController> _variationSkuCtrls = [];
  final List<TextEditingController> _variationSizeCtrls = [];
  final List<TextEditingController> _variationColorCtrls = [];
  final List<TextEditingController> _variationMaterialCtrls = [];
  final List<TextEditingController> _variationWeightCtrls = [];

  // Tags
  final _tagCtrl = TextEditingController();
  final List<String> _tags = [];
  List<String> _showOnPages = ['Shop'];
  List<String> _selectedRelatedProductIds = [];
  List<dynamic> _allProducts = [];
  final ScrollController _variationScrollController = ScrollController();

  bool _isLoading = false;
  String? _validationError;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    if (widget.product != null) {
      final p = widget.product!;
      _productNameCtrl.text = p['name'] ?? '';
      _shortDescCtrl.text = p['shortDescription'] ?? '';
      _fullDescCtrl.text = p['description'] ?? '';
      _brandCtrl.text = p['brand'] ?? '';
      _selectedCategory = p['category'];
      _selectedSubCategory = p['subCategory'];
      final double pPrice = (p['price'] ?? 0.0).toDouble();
      final double pDiscPrice = (p['discountPrice'] ?? 0.0).toDouble();
      _regularPriceCtrl.text = pPrice > 0 ? pPrice.toString() : '';
      if (pDiscPrice > 0 && pPrice > pDiscPrice) {
        final double calcPercent = ((pPrice - pDiscPrice) / pPrice) * 100;
        _discountedPriceCtrl.text = calcPercent.round().toString();
      } else {
        _discountedPriceCtrl.text = '';
      }
      _youtubeCtrl.text = p['youtubeLink'] ?? '';
      _mainImageUrl = p['image'];
      if (p['gallery'] != null) {
        _galleryUrls.addAll(List<String>.from(p['gallery']));
      }
      _productStatus = p['status'] ?? 'Draft';
      _visibility = p['visibility'] ?? 'Public';
      
      // Ensure the loaded values are present in the dropdown items to prevent crashes
      final List<String> statusOptions = ['Draft', 'Active', 'Archived'];
      if (!statusOptions.contains(_productStatus)) _productStatus = 'Draft';

      final List<String> visibilityOptions = ['Public', 'Private', 'Password Protected'];
      if (!visibilityOptions.contains(_visibility)) _visibility = 'Public';
      _skuCtrl.text = p['sku'] ?? '';
      _quantityCtrl.text = (p['stock'] ?? 0).toString();
      _lowStockCtrl.text = (p['lowStockThreshold'] ?? 5).toString();
      _trackQuantity = p['trackQuantity'] ?? true;
      _weightCtrl.text = (p['weight'] ?? 0.5).toString();
      if (p['dimensions'] != null) {
        _lengthCtrl.text = (p['dimensions']['length'] ?? '').toString();
        _widthCtrl.text = (p['dimensions']['width'] ?? '').toString();
        _heightCtrl.text = (p['dimensions']['height'] ?? '').toString();
      }
      _requiresShipping = p['requiresShipping'] ?? true;
      _seoTitleCtrl.text = p['seoTitle'] ?? '';
      _seoDescCtrl.text = p['seoDescription'] ?? '';
      _slugCtrl.text = p['slug'] ?? '';
      if (p['specs'] != null) {
        for (var spec in p['specs']) {
          _specKeyCtrls.add(TextEditingController(text: spec['key'] ?? ''));
          _specValCtrls.add(TextEditingController(text: spec['value'] ?? ''));
        }
      }
      if (p['attributes'] != null) {
        _sizeAttr = p['attributes']['size'] ?? false;
        _colorAttr = p['attributes']['color'] ?? false;
        _materialAttr = p['attributes']['material'] ?? false;
      }
      if (p['variations'] != null) {
        _variations = List<Map<String, dynamic>>.from(
          (p['variations'] as List).map((v) {
            final map = Map<String, dynamic>.from(v);
            List<String> imgs = [];
            if (map['images'] != null && map['images'] is List) {
              imgs = List<String>.from((map['images'] as List).map((e) => e.toString()));
            } else if (map['image'] != null && map['image'].toString().isNotEmpty) {
              imgs = [map['image'].toString()];
            }
            map['images'] = imgs;
            if (map['image'] == null || map['image'].toString().isEmpty) {
              map['image'] = imgs.isNotEmpty ? imgs[0] : '';
            }
            return map;
          }),
        );
        _syncVariationControllers();
      }
      if (p['tags'] != null) {
        _tags.addAll(List<String>.from(p['tags']));
      }
      if (p['showOnPages'] != null) {
        _showOnPages = List<String>.from(p['showOnPages']);
      }
      if (p['relatedProducts'] != null) {
        _selectedRelatedProductIds = List<String>.from(p['relatedProducts']);
      }
      _gstCtrl.text = (p['gst'] ?? 0).toString();
      _hsnCodeCtrl.text = p['hsnCode'] ?? '';
      _moqCtrl.text = (p['moq'] ?? 1).toString();
      _moqDiscountCtrl.text = (p['moqDiscount'] ?? 0).toString();
      _moqTiersCtrl.text = (p['moqTiers'] ?? '').toString();
    } else {
      _fullDescCtrl.text = '• ';
      for (var key in ['Size', 'Weight', 'Colour', 'Care Instructions', 'Basic Metal']) {
        _specKeyCtrls.add(TextEditingController(text: key));
        _specValCtrls.add(TextEditingController());
      }
    }
    _fetchAllProducts();
    _prevFullDescText = _fullDescCtrl.text;
    _fullDescCtrl.addListener(_handleFullDescChange);
  }

  Future<void> _fetchAllProducts() async {
    try {
      final products = await sl<ProductService>().getProducts();
      setState(() {
        _allProducts = products;
      });
    } catch (e) {
      debugPrint('Error fetching all products: $e');
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final categories = await sl<CategoryService>().getCategories(tree: true);
      setState(() {
        _categories = categories;
        if (_selectedCategory != null) {
          final selectedCat = _categories.firstWhere(
            (c) => c['name'] == _selectedCategory,
            orElse: () => null,
          );
          if (selectedCat != null) {
            _subCategories = selectedCat['subcategories'] ?? [];
          }
        }
      });
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
  }

  String _generateSmartSKU(String name, String size, String color, String material, [String weight = '']) {
    String catPrefix = _selectedCategory != null && _selectedCategory!.length >= 3 
        ? _selectedCategory!.substring(0, 3).toLowerCase() 
        : 'gen';
        
    String namePrefix = name.length >= 3 ? name.substring(0, 3).toLowerCase() : name.toLowerCase();
    if (namePrefix.isEmpty) namePrefix = 'prd';
    
    List<String> parts = [catPrefix, namePrefix];
    if (color.isNotEmpty) parts.add(color.toLowerCase().replaceAll(' ', ''));
    if (size.isNotEmpty) parts.add(size.toLowerCase().replaceAll(' ', ''));
    if (material.isNotEmpty) parts.add(material.toLowerCase().replaceAll(' ', ''));
    if (weight.isNotEmpty) parts.add(weight.toLowerCase().replaceAll(' ', ''));
    
    String randomSuffix = (100 + (DateTime.now().millisecondsSinceEpoch % 900)).toString();
    parts.add(randomSuffix);

    return parts.join('-');
  }
  void _generateVariations() {
    if (_sizeAttr) {
      final sizeOptions = _sizeOptionsCtrl.text.split(',');
      for (var opt in sizeOptions) {
        final val = opt.trim();
        if (val.isNotEmpty) {
          final cm = _parseSizeToCm(val);
          if (cm != null && cm > 100.0) {
            setState(() {
              _validationError = 'Variation size option "$val" exceeds 100 cm limit';
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_validationError!), backgroundColor: Colors.red),
            );
            return;
          }
        }
      }
    }

    if (_weightAttr) {
      final weightOptions = _weightOptionsCtrl.text.split(',');
      for (var opt in weightOptions) {
        final val = opt.trim();
        if (val.isNotEmpty) {
          final gm = _parseWeightToGm(val);
          if (gm != null && gm > 5000.0) {
            setState(() {
              _validationError = 'Variation weight option "$val" exceeds 5000 gm limit';
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_validationError!), backgroundColor: Colors.red),
            );
            return;
          }
        }
      }
    }

    List<String> sizes = _sizeAttr ? _sizeOptionsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList() : [''];
    List<String> colors = _colorAttr ? _colorOptionsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList() : [''];
    List<String> materials = _materialAttr ? _materialOptionsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList() : [''];
    List<String> weights = _weightAttr ? _weightOptionsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList() : [''];

    List<Map<String, dynamic>> newVariations = [];
    for (var s in sizes) {
      for (var c in colors) {
        for (var m in materials) {
          for (var w in weights) {
            if (s.isEmpty && c.isEmpty && m.isEmpty && w.isEmpty) continue;
            String varTitle = [s, c, m, w].where((e) => e.isNotEmpty).join(' / ');
            newVariations.add({
              'title': varTitle,
              'size': s,
              'color': c,
              'material': m,
              'weight': w,
              'price': double.tryParse(_regularPriceCtrl.text) ?? 0.0,
              'stock': int.tryParse(_quantityCtrl.text) ?? 0,
              'sku': _generateSmartSKU(_productNameCtrl.text, s, c, m, w),
              'image': '',
              'images': <String>['', '', ''],
            });
          }
        }
      }
    }
    setState(() {
      _validationError = null;
      _variations = newVariations;
      _syncVariationControllers();
    });
  }

  Future<void> _pickAndUploadVariationImage(int varIdx, int imgIdx) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('Uploading variation image...'),
            ],
          ),
          duration: Duration(days: 1),
        ),
      );

      final bytes = await image.readAsBytes();
      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(bytes, filename: 'variation_${varIdx}_$imgIdx.png'),
      });

      final response = await sl<ApiService>().dio.post('/upload/image', data: formData);

      ScaffoldMessenger.of(context).clearSnackBars();

      if (response.statusCode == 200 && response.data['success'] == true) {
        final imageUrl = response.data['url'];
        setState(() {
          if (_syncVariationDetails) {
            for (var v in _variations) {
              List<String> imgs = [];
              if (v['images'] != null && (v['images'] as List).isNotEmpty) {
                imgs = List<String>.from(v['images']);
              } else if (v['image'] != null && v['image'].toString().isNotEmpty) {
                imgs = [v['image'].toString()];
              }
              while (imgs.length <= imgIdx) {
                imgs.add('');
              }
              imgs[imgIdx] = imageUrl;
              v['images'] = imgs;
              if (imgIdx == 0) {
                v['image'] = imageUrl;
              }
            }
          } else {
            var v = _variations[varIdx];
            List<String> imgs = [];
            if (v['images'] != null && (v['images'] as List).isNotEmpty) {
              imgs = List<String>.from(v['images']);
            } else if (v['image'] != null && v['image'].toString().isNotEmpty) {
              imgs = [v['image'].toString()];
            }
            while (imgs.length <= imgIdx) {
              imgs.add('');
            }
            imgs[imgIdx] = imageUrl;
            v['images'] = imgs;
            if (imgIdx == 0) {
              v['image'] = imageUrl;
            }
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Variation image uploaded successfully'), backgroundColor: Colors.green),
        );
      } else {
        throw Exception(response.data['message'] ?? 'Failed to upload image');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
      );
    }
  }


  Future<void> _pickMainImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _mainImage = image;
        _mainImageUrl = null;
      });
    }
  }

  Future<void> _pickGalleryImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _galleryImages.add(image);
      });
    }
  }

  Future<void> _generateWithAI() async {
    final name = _productNameCtrl.text.trim();
    final shortDesc = _shortDescCtrl.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a product name first'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await sl<ApiService>().dio.post('/vendor/generate-ai', data: {
        'productName': name,
        'shortDescription': shortDesc,
      });

      if (response.statusCode == 200) {
        final data = response.data['data'];
        
        setState(() {
          if (data['description'] != null) {
            _fullDescCtrl.text = data['description'];
          }
          
          if (data['specs'] != null && data['specs'] is List) {
            _specKeyCtrls.clear();
            _specValCtrls.clear();
            for (var spec in data['specs']) {
              _specKeyCtrls.add(TextEditingController(text: spec.toString()));
              _specValCtrls.add(TextEditingController(text: 'Yes'));
            }
          }
          
          if (data['tags'] != null && data['tags'] is List) {
            _tagCtrl.text = (data['tags'] as List).join(', ');
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Content generated successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      print('Error generating AI content: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate content: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProduct() async {
    List<String> missing = [];
    if (_productNameCtrl.text.trim().isEmpty) missing.add('Display Title');
    if (_shortDescCtrl.text.trim().isEmpty) missing.add('Package Includes');
    if (_selectedCategory == null || _selectedCategory!.trim().isEmpty) missing.add('Category');
    if (_selectedSubCategory == null || _selectedSubCategory!.trim().isEmpty) missing.add('Sub Category');
    if (_regularPriceCtrl.text.trim().isEmpty) missing.add('Regular Price');
    if (_gstCtrl.text.trim().isEmpty) missing.add('GST (%)');
    if (_hsnCodeCtrl.text.trim().isEmpty) missing.add('HSN Code');
    if (_skuCtrl.text.trim().isEmpty) missing.add('SKU');
    if (_quantityCtrl.text.trim().isEmpty) missing.add('Quantity');
    if (_moqCtrl.text.trim().isEmpty) missing.add('Minimum Order Quantity (MOQ)');

    if (missing.isNotEmpty) {
      setState(() {
        _validationError = 'Required fields missing: ${missing.join(', ')}';
      });
      return;
    }

    // Value format/range validation according to field type
    final double? regularPrice = double.tryParse(_regularPriceCtrl.text.trim());
    if (regularPrice == null || regularPrice <= 0) {
      setState(() {
        _validationError = 'Regular Price must be a valid number greater than 0';
      });
      return;
    }

    final double? gst = double.tryParse(_gstCtrl.text.trim());
    if (gst == null || gst < 0) {
      setState(() {
        _validationError = 'GST (%) must be a valid number greater than or equal to 0';
      });
      return;
    }

    final hsnCode = _hsnCodeCtrl.text.trim();
    if (hsnCode.length != 6) {
      setState(() {
        _validationError = 'HSN Code must be exactly 6 digits';
      });
      return;
    }

    final int? quantity = int.tryParse(_quantityCtrl.text.trim());
    if (quantity == null || quantity < 0) {
      setState(() {
        _validationError = 'Quantity must be a valid non-negative integer';
      });
      return;
    }

    final int? moq = int.tryParse(_moqCtrl.text.trim());
    if (moq == null || moq < 1) {
      setState(() {
        _validationError = 'Minimum Order Quantity (MOQ) must be a valid integer greater than or equal to 1';
      });
      return;
    }

    // Validate specifications
    for (var requiredKey in ['Size', 'Weight', 'Colour', 'Care Instructions', 'Basic Metal']) {
      bool foundAndFilled = false;
      for (int i = 0; i < _specKeyCtrls.length; i++) {
        final keyText = _specKeyCtrls[i].text.trim().replaceAll(' *', '').toLowerCase();
        final reqKeyLower = requiredKey.toLowerCase();
        
        bool isMatch = false;
        if (reqKeyLower == 'care instructions') {
          isMatch = keyText == 'care instructions' || keyText == 'care instruction';
        } else if (reqKeyLower == 'colour') {
          isMatch = keyText == 'colour' || keyText == 'color';
        } else {
          isMatch = keyText == reqKeyLower;
        }

        if (isMatch && _specValCtrls[i].text.trim().isNotEmpty) {
          foundAndFilled = true;
          break;
        }
      }
      if (!foundAndFilled) {
        setState(() {
          _validationError = '$requiredKey is required in Specifications';
        });
        return;
      }
    }

    double weightInKg = 0.0;
    final String weightText = _weightCtrl.text.trim();
    if (weightText.isNotEmpty) {
      final cleaned = weightText.toLowerCase();
      final double? numPart = double.tryParse(cleaned.replaceAll(RegExp(r'[^0-9.]'), ''));
      if (numPart == null) {
        setState(() {
          _validationError = 'Weight must be a valid number';
        });
        return;
      }

      if (cleaned.endsWith('kg') || cleaned.endsWith('kilogram') || cleaned.endsWith('kilograms')) {
        weightInKg = numPart;
      } else if (cleaned.endsWith('g') || cleaned.endsWith('gm') || cleaned.endsWith('gram') || cleaned.endsWith('grams')) {
        weightInKg = numPart / 1000.0;
      } else {
        // Plain number
        if (numPart > 5000.0) {
          setState(() {
            _validationError = 'Weight cannot exceed 5000g (5 kg)';
          });
          return;
        } else if (numPart > 5.0 && numPart <= 20.0) {
          setState(() {
            _validationError = 'Weight cannot exceed 5 kg (5000g)';
          });
          return;
        } else if (numPart > 20.0) {
          // Treated as grams
          weightInKg = numPart / 1000.0;
        } else {
          // <= 5.0, treated as kg
          weightInKg = numPart;
        }
      }

      if (weightInKg > 5.0) {
        setState(() {
          _validationError = 'Weight cannot exceed 5 kg (5000g)';
        });
        return;
      }
    }

    // Validate main product dimensions
    final mainLength = double.tryParse(_lengthCtrl.text.trim()) ?? 0.0;
    final mainWidth = double.tryParse(_widthCtrl.text.trim()) ?? 0.0;
    final mainHeight = double.tryParse(_heightCtrl.text.trim()) ?? 0.0;
    if (mainLength > 100.0 || mainWidth > 100.0 || mainHeight > 100.0) {
      setState(() {
        _validationError = 'Dimensions (Length, Width, Height) cannot exceed 100 cm';
      });
      return;
    }

    // Validate variation attributes size and weight options
    if (_sizeAttr) {
      final sizeOptions = _sizeOptionsCtrl.text.split(',');
      for (var opt in sizeOptions) {
        final val = opt.trim();
        if (val.isNotEmpty) {
          final cm = _parseSizeToCm(val);
          if (cm != null && cm > 100.0) {
            setState(() {
              _validationError = 'Variation size option "$val" exceeds 100 cm limit';
            });
            return;
          }
        }
      }
    }

    if (_weightAttr) {
      final weightOptions = _weightOptionsCtrl.text.split(',');
      for (var opt in weightOptions) {
        final val = opt.trim();
        if (val.isNotEmpty) {
          final gm = _parseWeightToGm(val);
          if (gm != null && gm > 5000.0) {
            setState(() {
              _validationError = 'Variation weight option "$val" exceeds 5000 gm limit';
            });
            return;
          }
        }
      }
    }

    setState(() {
      _validationError = null;
      _isLoading = true;
    });

    try {
      final List<Map<String, String>> specs = [];
      for (int i = 0; i < _specKeyCtrls.length; i++) {
        if (_specKeyCtrls[i].text.isNotEmpty) {
          specs.add({
            'key': _specKeyCtrls[i].text,
            'value': _specValCtrls[i].text,
          });
        }
      }

      final double regPrice = double.tryParse(_regularPriceCtrl.text) ?? 0.0;
      final double discPercent = double.tryParse(_discountedPriceCtrl.text) ?? 0.0;
      final double calcDiscountPrice = (discPercent > 0 && discPercent <= 100) 
          ? regPrice - (regPrice * discPercent / 100) 
          : 0.0;

      final productData = {
        'name': _productNameCtrl.text,
        'title': _productNameCtrl.text,
        'price': regPrice,
        'discountPrice': calcDiscountPrice,
        'description': _fullDescCtrl.text, 
        'shortDescription': _shortDescCtrl.text,
        'category': _selectedCategory ?? 'General',
        'subCategory': _selectedSubCategory ?? '',
        'brand': _brandCtrl.text,
        'sku': _skuCtrl.text,
        'stock': int.tryParse(_quantityCtrl.text) ?? 0,
        'lowStockThreshold': int.tryParse(_lowStockCtrl.text) ?? 5,
        'trackQuantity': _trackQuantity,
        'weight': weightInKg,
        'length': double.tryParse(_lengthCtrl.text) ?? 0.0,
        'width': double.tryParse(_widthCtrl.text) ?? 0.0,
        'height': double.tryParse(_heightCtrl.text) ?? 0.0,
        'requiresShipping': _requiresShipping,
        'seoTitle': _seoTitleCtrl.text,
        'seoDescription': _seoDescCtrl.text,
        'slug': _slugCtrl.text,
        'youtubeLink': _youtubeCtrl.text,
        'status': _productStatus,
        'visibility': _visibility,
        'image': _mainImageUrl ?? '',
        'gallery': jsonEncode(_galleryUrls),
        'attributes': jsonEncode({
          'size': _sizeAttr,
          'color': _colorAttr,
          'material': _materialAttr,
          'weight': _weightAttr,
        }),
        'variations': jsonEncode(_variations),
        'specs': jsonEncode(specs),
        'tags': jsonEncode(_tags),
        'showOnPages': jsonEncode(_showOnPages),
        'relatedProducts': jsonEncode(_selectedRelatedProductIds),
        'gst': double.tryParse(_gstCtrl.text) ?? 0.0,
        'hsnCode': _hsnCodeCtrl.text,
        'moq': int.tryParse(_moqCtrl.text) ?? 1,
        'moqDiscount': double.tryParse(_moqDiscountCtrl.text) ?? 0.0,
        'moqTiers': _moqTiersCtrl.text.trim(),
      };

      if (widget.product != null) {
        await sl<ProductService>().updateProduct(widget.product!['_id'], productData, mainImage: _mainImage, gallery: _galleryImages);
      } else {
        await sl<ProductService>().createProduct(productData, mainImage: _mainImage, gallery: _galleryImages);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.product != null ? 'Product updated successfully' : 'Product saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/products');
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          errorMessage = data['message'];
        } else if (e.message != null) {
          errorMessage = e.message!;
        }
      }
      if (mounted) {
        setState(() {
          _validationError = 'Failed to save product: $errorMessage';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _fullDescCtrl.removeListener(_handleFullDescChange);
    _skuCtrl.dispose();
    _productNameCtrl.dispose();
    _shortDescCtrl.dispose();
    _fullDescCtrl.dispose();
    _brandCtrl.dispose();
    _regularPriceCtrl.dispose();
    _discountedPriceCtrl.dispose();
    _gstCtrl.dispose();
    _hsnCodeCtrl.dispose();
    _moqCtrl.dispose();
    _moqDiscountCtrl.dispose();
    _moqTiersCtrl.dispose();
    _youtubeCtrl.dispose();
    _quantityCtrl.dispose();
    _lowStockCtrl.dispose();
    _weightCtrl.dispose();
    _lengthCtrl.dispose();
    _widthCtrl.dispose();
    _heightCtrl.dispose();
    _seoTitleCtrl.dispose();
    _seoDescCtrl.dispose();
    _slugCtrl.dispose();
    _tagCtrl.dispose();
    _sizeOptionsCtrl.dispose();
    _colorOptionsCtrl.dispose();
    _materialOptionsCtrl.dispose();
    _weightOptionsCtrl.dispose();
    for (var ctrl in _specKeyCtrls) {
      ctrl.dispose();
    }
    for (var ctrl in _specValCtrls) {
      ctrl.dispose();
    }
    for (var ctrl in _variationPriceCtrls) ctrl.dispose();
    for (var ctrl in _variationOldPriceCtrls) ctrl.dispose();
    for (var ctrl in _variationStockCtrls) ctrl.dispose();
    for (var ctrl in _variationTitleCtrls) ctrl.dispose();
    for (var ctrl in _variationSkuCtrls) ctrl.dispose();
    for (var ctrl in _variationSizeCtrls) ctrl.dispose();
    for (var ctrl in _variationColorCtrls) ctrl.dispose();
    for (var ctrl in _variationMaterialCtrls) ctrl.dispose();
    for (var ctrl in _variationWeightCtrls) ctrl.dispose();
    _variationScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const VendorTopBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // ── Page Header ──────────────────────────────────────
            Row(
              children: [
                IconButton(
                  onPressed: () => context.go('/products'),
                  icon: const Icon(Icons.arrow_back, size: 20),
                  style: IconButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add New Product',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Create or update product information',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _generateWithAI,
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: Text(
                    'Generate with AI',
                    style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
               
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveProduct,
                  icon: _isLoading 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.storefront_outlined, size: 16),
                  label: Text(
                    _isLoading ? 'Saving...' : 'Save Product',
                    style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            if (_validationError != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade100),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _validationError!,
                  style: GoogleFonts.inter(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),

            // ── Two-column layout ────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── LEFT COLUMN ──────────────────────────────────
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildBasicInfoCard(),
                      const SizedBox(height: 20),
                      _buildPricingCard(),
                      const SizedBox(height: 20),
                      _buildMediaCard(),
                      const SizedBox(height: 16),
                      _buildShippingCard(),
                      const SizedBox(height: 16),
                      _buildSEOCard(),
                    ],
                  ),
                ),

                const SizedBox(width: 24),

                // ── RIGHT COLUMN ─────────────────────────────────
                SizedBox(
                  width: 320,
                  child: Column(
                    children: [
                      _buildStatusAndVisibilityCard(),
                      const SizedBox(height: 16),
                      _buildInventoryCard(),
                      const SizedBox(height: 16),
                      _buildTagsCard(),
                      const SizedBox(height: 16),
                      _buildRelatedProductsCard(),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Specifications Card (styled for full width)
            _buildSpecificationsCard(),
            const SizedBox(height: 24),
            // Product Variations Card (styled for full width)
            _buildVariationsCard(),
          ],
        ),
      ),
    )
    );
  }

  void updateState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  void _handleFullDescChange() {
    final text = _fullDescCtrl.text;
    final selection = _fullDescCtrl.selection;

    if (text.isEmpty) {
      _fullDescCtrl.value = const TextEditingValue(
        text: '• ',
        selection: TextSelection.collapsed(offset: 2),
      );
      _prevFullDescText = '• ';
      return;
    }

    if (!text.startsWith('• ')) {
      final newText = '• ' + text;
      _fullDescCtrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
            offset: selection.baseOffset >= 0 ? selection.baseOffset + 2 : 2),
      );
      _prevFullDescText = newText;
      return;
    }

    if (_autoBulletMode &&
        text.length == _prevFullDescText.length + 1 &&
        selection.isCollapsed &&
        selection.baseOffset > 0) {
      final lastTypedChar = text[selection.baseOffset - 1];
      if (lastTypedChar == '\n') {
        final newText = text.substring(0, selection.baseOffset) +
            '• ' +
            text.substring(selection.baseOffset);
        _fullDescCtrl.value = TextEditingValue(
          text: newText,
          selection:
              TextSelection.collapsed(offset: selection.baseOffset + 2),
        );
      }
    }
    _prevFullDescText = text;
  }

  double? _parseWeightToGm(String input) {
    final cleaned = input.toLowerCase().trim();
    final numPart = double.tryParse(cleaned.replaceAll(RegExp(r'[^0-9.]'), ''));
    if (numPart == null) return null;
    if (cleaned.endsWith('kg') || cleaned.endsWith('kilogram') || cleaned.endsWith('kilograms')) {
      return numPart * 1000;
    }
    return numPart;
  }

  double? _parseSizeToCm(String input) {
    final cleaned = input.toLowerCase().trim();
    final numPart = double.tryParse(cleaned.replaceAll(RegExp(r'[^0-9.]'), ''));
    if (numPart == null) return null;
    if (cleaned.endsWith('m') && !cleaned.endsWith('cm') && !cleaned.endsWith('mm')) {
      return numPart * 100;
    }
    if (cleaned.endsWith('inch') || cleaned.endsWith('inches') || cleaned.endsWith('"')) {
      return numPart * 2.54;
    }
    return numPart;
  }

  void _syncVariationControllers() {
    for (var ctrl in _variationPriceCtrls) ctrl.dispose();
    for (var ctrl in _variationOldPriceCtrls) ctrl.dispose();
    for (var ctrl in _variationStockCtrls) ctrl.dispose();
    for (var ctrl in _variationTitleCtrls) ctrl.dispose();
    for (var ctrl in _variationSkuCtrls) ctrl.dispose();
    for (var ctrl in _variationSizeCtrls) ctrl.dispose();
    for (var ctrl in _variationColorCtrls) ctrl.dispose();
    for (var ctrl in _variationMaterialCtrls) ctrl.dispose();
    for (var ctrl in _variationWeightCtrls) ctrl.dispose();
    _variationPriceCtrls.clear();
    _variationOldPriceCtrls.clear();
    _variationStockCtrls.clear();
    _variationTitleCtrls.clear();
    _variationSkuCtrls.clear();
    _variationSizeCtrls.clear();
    _variationColorCtrls.clear();
    _variationMaterialCtrls.clear();
    _variationWeightCtrls.clear();

    for (var v in _variations) {
      _variationPriceCtrls.add(TextEditingController(text: (v['price'] ?? 0.0).toString()));
      _variationOldPriceCtrls.add(TextEditingController(text: (v['oldPrice'] ?? v['price'] ?? 0.0).toString()));
      _variationStockCtrls.add(TextEditingController(text: (v['stock'] ?? 0).toString()));
      _variationTitleCtrls.add(TextEditingController(text: v['title']?.toString() ?? ''));
      _variationSkuCtrls.add(TextEditingController(text: v['sku']?.toString() ?? ''));
      _variationSizeCtrls.add(TextEditingController(text: v['size']?.toString() ?? ''));
      _variationColorCtrls.add(TextEditingController(text: v['color']?.toString() ?? ''));
      _variationMaterialCtrls.add(TextEditingController(text: v['material']?.toString() ?? ''));
      _variationWeightCtrls.add(TextEditingController(text: v['weight']?.toString() ?? ''));
    }
  }

  void _recalculateVariationPrices() {
    final discountPercent = double.tryParse(_discountedPriceCtrl.text) ?? 0.0;
    for (int i = 0; i < _variations.length; i++) {
      final double mrp = double.tryParse(_variationOldPriceCtrls[i].text) ?? 0.0;
      if (discountPercent > 0) {
        final double sellingPrice = mrp * (1 - discountPercent / 100);
        _variations[i]['price'] = sellingPrice;
        _variationPriceCtrls[i].text = sellingPrice.toStringAsFixed(2);
      } else {
        _variations[i]['price'] = mrp;
        _variationPriceCtrls[i].text = mrp.toStringAsFixed(2);
      }
    }
  }
}
