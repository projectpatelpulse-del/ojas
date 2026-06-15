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

class AddProductPage extends StatefulWidget {
  final dynamic product;
  const AddProductPage({super.key, this.product});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  // Basic Info
  final _productNameCtrl = TextEditingController();
  final _productTitleCtrl = TextEditingController();
  final _shortDescCtrl = TextEditingController();
  final _fullDescCtrl = TextEditingController();
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
  final _sizeOptionsCtrl = TextEditingController();
  final _colorOptionsCtrl = TextEditingController();
  final _materialOptionsCtrl = TextEditingController();
  List<Map<String, dynamic>> _variations = [];

  // Tags
  final _tagCtrl = TextEditingController();
  final List<String> _tags = [];
  List<String> _showOnPages = ['Shop'];
  List<String> _selectedRelatedProductIds = [];
  List<dynamic> _allProducts = [];

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
      _productTitleCtrl.text = p['title'] ?? '';
      _shortDescCtrl.text = p['shortDescription'] ?? '';
      _fullDescCtrl.text = p['description'] ?? '';
      _brandCtrl.text = p['brand'] ?? '';
      _selectedCategory = p['category'];
      _selectedSubCategory = p['subCategory'];
      _regularPriceCtrl.text = (p['price'] ?? 0.0).toString();
      _discountedPriceCtrl.text = (p['discountPrice'] ?? 0.0).toString();
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
          (p['variations'] as List).map((v) => Map<String, dynamic>.from(v)),
        );
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
    }
    _fetchAllProducts();
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

  String _generateSmartSKU(String name, String size, String color, String material) {
    String catPrefix = _selectedCategory != null && _selectedCategory!.length >= 3 
        ? _selectedCategory!.substring(0, 3).toLowerCase() 
        : 'gen';
        
    String namePrefix = name.length >= 3 ? name.substring(0, 3).toLowerCase() : name.toLowerCase();
    if (namePrefix.isEmpty) namePrefix = 'prd';
    
    List<String> parts = [catPrefix, namePrefix];
    if (color.isNotEmpty) parts.add(color.toLowerCase().replaceAll(' ', ''));
    if (size.isNotEmpty) parts.add(size.toLowerCase().replaceAll(' ', ''));
    if (material.isNotEmpty) parts.add(material.toLowerCase().replaceAll(' ', ''));
    
    String randomSuffix = (100 + (DateTime.now().millisecondsSinceEpoch % 900)).toString();
    parts.add(randomSuffix);

    return parts.join('-');
  }
  void _generateVariations() {
    List<String> sizes = _sizeAttr ? _sizeOptionsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList() : [''];
    List<String> colors = _colorAttr ? _colorOptionsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList() : [''];
    List<String> materials = _materialAttr ? _materialOptionsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList() : [''];

    List<Map<String, dynamic>> newVariations = [];
    for (var s in sizes) {
      for (var c in colors) {
        for (var m in materials) {
          if (s.isEmpty && c.isEmpty && m.isEmpty) continue;
          newVariations.add({
            'size': s,
            'color': c,
            'material': m,
            'price': double.tryParse(_regularPriceCtrl.text) ?? 0.0,
            'stock': int.tryParse(_quantityCtrl.text) ?? 0,
            'sku': _generateSmartSKU(_productNameCtrl.text, s, c, m),
            'image': '',
          });
        }
      }
    }
    setState(() {
      _variations = newVariations;
    });
  }

  Future<void> _pickAndUploadVariationImage(int idx) async {
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
        'image': MultipartFile.fromBytes(bytes, filename: 'variation_$idx.png'),
      });

      final response = await sl<ApiService>().dio.post('/upload/image', data: formData);

      ScaffoldMessenger.of(context).clearSnackBars();

      if (response.statusCode == 200 && response.data['success'] == true) {
        final imageUrl = response.data['url'];
        setState(() {
          _variations[idx]['image'] = imageUrl;
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
    if (_productNameCtrl.text.isEmpty) missing.add('Product Name');
    if (_selectedCategory == null) missing.add('Category');

    if (missing.isNotEmpty) {
      setState(() {
        _validationError = 'Required fields missing: ${missing.join(', ')}';
      });
      return;
    }

    final hsnCode = _hsnCodeCtrl.text.trim();
    if (hsnCode.isEmpty) {
      setState(() {
        _validationError = 'HSN Code is required';
      });
      return;
    }
    if (hsnCode.length != 6) {
      setState(() {
        _validationError = 'HSN Code must be exactly 6 digits';
      });
      return;
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

      final productData = {
        'name': _productNameCtrl.text,
        'title': _productTitleCtrl.text.isEmpty ? _productNameCtrl.text : _productTitleCtrl.text,
        'price': double.tryParse(_regularPriceCtrl.text) ?? 0.0,
        'discountPrice': double.tryParse(_discountedPriceCtrl.text) ?? 0.0,
        'description': _fullDescCtrl.text, 
        'shortDescription': _shortDescCtrl.text,
        'category': _selectedCategory ?? 'General',
        'subCategory': _selectedSubCategory ?? '',
        'brand': _brandCtrl.text,
        'sku': _skuCtrl.text,
        'stock': int.tryParse(_quantityCtrl.text) ?? 0,
        'lowStockThreshold': int.tryParse(_lowStockCtrl.text) ?? 5,
        'trackQuantity': _trackQuantity,
        'weight': double.tryParse(_weightCtrl.text) ?? 0.0,
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
    _skuCtrl.dispose();
    _productNameCtrl.dispose();
    _productTitleCtrl.dispose();
    _shortDescCtrl.dispose();
    _fullDescCtrl.dispose();
    _brandCtrl.dispose();
    _regularPriceCtrl.dispose();
    _discountedPriceCtrl.dispose();
    _gstCtrl.dispose();
    _hsnCodeCtrl.dispose();
    _moqCtrl.dispose();
    _moqDiscountCtrl.dispose();
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
    for (var ctrl in _specKeyCtrls) {
      ctrl.dispose();
    }
    for (var ctrl in _specValCtrls) {
      ctrl.dispose();
    }
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
                // OutlinedButton.icon(
                //   onPressed: _isLoading ? null : _generateWithAI,
                //   icon: const Icon(Icons.auto_awesome, size: 16),
                //   label: Text(
                //     'Generate with AI',
                //     style: GoogleFonts.inter(
                //         fontSize: 13, fontWeight: FontWeight.w500),
                //   ),
                //   style: OutlinedButton.styleFrom(
                //     foregroundColor: AppColors.primary,
                //     side: const BorderSide(color: AppColors.primary),
                //     padding: const EdgeInsets.symmetric(
                //         horizontal: 16, vertical: 14),
                //     shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(8)),
                //   ),
               
                // ),
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
                      // Basic Information
                      _card(
                        title: 'Basic Information',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fieldLabel('Product Name', required: true),
                            const SizedBox(height: 6),
                            _textField(
                                controller: _productNameCtrl,
                                hint: 'e.g. Premium Silk Scarf'),
                            const SizedBox(height: 16),
                            _fieldLabel('Display Title'),
                            const SizedBox(height: 6),
                            _textField(
                                controller: _productTitleCtrl,
                                hint: 'Product title as seen by customers'),
                            const SizedBox(height: 16),
                            _fieldLabel('Short Description', required: true),
                            const SizedBox(height: 6),
                            _textField(
                              controller: _shortDescCtrl,
                              hint: 'A quick summary (1-2 sentences)',
                              maxLines: 2,
                            ),
                            const SizedBox(height: 16),
                            _fieldLabel('Full Description'),
                            const SizedBox(height: 6),
                            _textField(
                              controller: _fullDescCtrl,
                              hint: 'Detailed product details, features, and story',
                              maxLines: 6,
                            ),
                            const SizedBox(height: 16),
                            _fieldLabel('Category', required: true),
                            const SizedBox(height: 6),
                            _dropdownField(
                              value: _selectedCategory,
                              hint: 'Select category',
                              items: _categories.map((c) => c['name'].toString()).toList(),
                              onChanged: (v) {
                                setState(() {
                                  _selectedCategory = v;
                                  _selectedSubCategory = null;
                                  final selectedCat = _categories.firstWhere((c) => c['name'] == v);
                                  _subCategories = selectedCat['subcategories'] ?? [];
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            _fieldLabel('Sub Category', required: true),
                            const SizedBox(height: 6),
                            _dropdownField(
                              value: _selectedSubCategory,
                              hint: 'Select sub category',
                              items: _subCategories.map((s) => s['name'].toString()).toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedSubCategory = v),
                            ),
                            const SizedBox(height: 16),
                            _fieldLabel('Brand'),
                            const SizedBox(height: 6),
                            _textField(
                                controller: _brandCtrl, hint: 'Brand name'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Pricing
                      _card(
                        title: 'Pricing',
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _fieldLabel('Regular Price', required: true),
                                      const SizedBox(height: 6),
                                      _textField(
                                          controller: _regularPriceCtrl,
                                          hint: '0.00',
                                          keyboardType:
                                              TextInputType.number),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _fieldLabel('Discounted Price'),
                                      const SizedBox(height: 6),
                                      _textField(
                                          controller: _discountedPriceCtrl,
                                          hint: '0.00',
                                          keyboardType:
                                              TextInputType.number),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _fieldLabel('GST (%)', required: true),
                                      const SizedBox(height: 6),
                                      _textField(
                                          controller: _gstCtrl,
                                          hint: 'e.g. 18',
                                          keyboardType:
                                              TextInputType.number),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
      _fieldLabel('HSN Code', required: true),
      const SizedBox(height: 6),
      _textField(
        controller: _hsnCodeCtrl,
        hint: 'e.g. 123456',
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Media
                      _card(
                        title: 'Media',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                _uploadBox(
                                  width: 90, 
                                  height: 80, 
                                  label: null,
                                  imageFile: _mainImage,
                                  imageUrl: _mainImageUrl,
                                  onTap: _pickMainImage,
                                ),
                                if (_mainImage != null || _mainImageUrl != null)
                                  Positioned(
                                    right: -6,
                                    top: -6,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _mainImage = null;
                                          _mainImageUrl = null;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, size: 12, color: Colors.white),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _fieldLabel('Gallery Images'),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                ..._galleryUrls.map((url) => Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    _uploadBox(
                                      width: 100,
                                      height: 80,
                                      label: null,
                                      imageUrl: url,
                                      onTap: () {},
                                    ),
                                    Positioned(
                                      right: -6,
                                      top: -6,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _galleryUrls.remove(url);
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close, size: 12, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                )),
                                ..._galleryImages.map((file) => Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    _uploadBox(
                                      width: 100,
                                      height: 80,
                                      label: null,
                                      imageFile: file,
                                      onTap: () {},
                                    ),
                                    Positioned(
                                      right: -6,
                                      top: -6,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _galleryImages.remove(file);
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close, size: 12, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                )),
                                _uploadBox(
                                  width: 100, 
                                  height: 80, 
                                  label: 'Add Image',
                                  onTap: _pickGalleryImage,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _fieldLabel('YouTube Video Link (optional)'),
                            const SizedBox(height: 6),
                            _textField(
                                controller: _youtubeCtrl,
                                hint: 'https://www.youtube.com/watch?v=...'),
                          ],
                        ),
                      ),

                    ],
                  ),
                ),

                const SizedBox(width: 24),

                // ── RIGHT COLUMN ─────────────────────────────────
                SizedBox(
                  width: 320,
                  child: Column(
                    children: [
                      // Status & Visibility
                      _card(
                        title: 'Status & Visibility',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fieldLabel('Product Status'),
                            const SizedBox(height: 8),
                            _selectionField(
                              value: _productStatus,
                              options: ['Draft', 'Active', 'Archived'],
                              onChanged: (v) => setState(() => _productStatus = v!),
                            ),
                            const SizedBox(height: 16),
                            _fieldLabel('Visibility'),
                            const SizedBox(height: 8),
                            _selectionField(
                              value: _visibility,
                              options: ['Public', 'Private', 'Password Protected'],
                              onChanged: (v) => setState(() => _visibility = v!),
                            ),
                            const SizedBox(height: 24),
                            _fieldLabel('Show on Pages'),
                            const SizedBox(height: 8),
                            Column(
                              children: ['Home', 'Features', 'Deals', 'Shop'].map((page) {
                                return Row(
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: Checkbox(
                                        value: _showOnPages.contains(page),
                                        activeColor: AppColors.primary,
                                        onChanged: (v) {
                                          setState(() {
                                            if (v == true) {
                                              if (!_showOnPages.contains(page)) {
                                                _showOnPages.add(page);
                                              }
                                            } else {
                                              if (page != 'Shop' || _showOnPages.length > 1) {
                                                _showOnPages.remove(page);
                                              }
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      page,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Inventory
                      _card(
                        title: 'Inventory',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: _fieldLabel('SKU (Stock Keeping Unit)')),
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _skuCtrl.text = _generateSmartSKU(_productNameCtrl.text, '', '', '');
                                    });
                                  },
                                  icon: const Icon(Icons.auto_awesome, size: 14),
                                  label: Text('Auto-Generate', style: GoogleFonts.inter(fontSize: 12)),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                    minimumSize: const Size(0, 24),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            _textField(
                                controller: _skuCtrl,
                                hint: 'e.g. PRD-CAT-001'),
                            const SizedBox(height: 14),
                            _fieldLabel('Quantity'),
                            const SizedBox(height: 6),
                            _textField(
                                controller: _quantityCtrl,
                                hint: '0',
                                keyboardType: TextInputType.number),
                            const SizedBox(height: 14),
                            _fieldLabel('Low Stock Threshold'),
                            const SizedBox(height: 6),
                            _textField(
                                controller: _lowStockCtrl,
                                hint: '5',
                                keyboardType: TextInputType.number),
                            const SizedBox(height: 14),
                            _fieldLabel('Minimum Order Quantity (MOQ)', required: true),
                            const SizedBox(height: 6),
                            _textField(
                                controller: _moqCtrl,
                                hint: '1',
                                keyboardType: TextInputType.number),
                            const SizedBox(height: 14),
                            _fieldLabel('MOQ Additional Discount (%)'),
                            const SizedBox(height: 6),
                            _textField(
                                controller: _moqDiscountCtrl,
                                hint: '0',
                                keyboardType: TextInputType.number),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Checkbox(
                                    value: _trackQuantity,
                                    activeColor: AppColors.primary,
                                    onChanged: (v) => setState(
                                        () => _trackQuantity = v!),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('Track quantity',
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: AppColors.textPrimary)),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Shipping
                      _card(
                        title: 'Shipping',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fieldLabel('Weight (kg)'),
                            const SizedBox(height: 6),
                            _textField(
                                controller: _weightCtrl,
                                hint: '0.5',
                                keyboardType: TextInputType.number),
                            const SizedBox(height: 14),
                            _fieldLabel('Dimensions (cm)'),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                    child: _textField(
                                        controller: _lengthCtrl,
                                        hint: 'Length')),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: _textField(
                                        controller: _widthCtrl,
                                        hint: 'Width')),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: _textField(
                                        controller: _heightCtrl,
                                        hint: 'Height')),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Checkbox(
                                    value: _requiresShipping,
                                    activeColor: AppColors.primary,
                                    onChanged: (v) => setState(
                                        () => _requiresShipping = v!),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('This product requires shipping',
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: AppColors.textPrimary)),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // SEO
                      _card(
                        title: 'SEO',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                _fieldLabel('SEO Title'),
                                Text('(0/60 characters)',
                                    style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            _textField(
                                controller: _seoTitleCtrl,
                                hint: 'Product title for search engines'),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                _fieldLabel('SEO Description'),
                                Text('(0/160 characters)',
                                    style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            _textField(
                              controller: _seoDescCtrl,
                              hint: 'Product description for search engines',
                              maxLines: 3,
                            ),
                            const SizedBox(height: 14),
                            _fieldLabel('URL Slug'),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    border: Border.all(
                                        color: Colors.grey.shade300),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      bottomLeft: Radius.circular(8),
                                    ),
                                  ),
                                  child: Text('yourstore.com/products/',
                                      style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppColors.textSecondary)),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _slugCtrl,
                                    style:
                                        GoogleFonts.inter(fontSize: 13),
                                    decoration: InputDecoration(
                                      hintText: 'product-name',
                                      hintStyle: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: Colors.grey.shade400),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 12),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            const BorderRadius.only(
                                          topRight: Radius.circular(8),
                                          bottomRight: Radius.circular(8),
                                        ),
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade300),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius:
                                            const BorderRadius.only(
                                          topRight: Radius.circular(8),
                                          bottomRight: Radius.circular(8),
                                        ),
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade300),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                            const BorderRadius.only(
                                          topRight: Radius.circular(8),
                                          bottomRight: Radius.circular(8),
                                        ),
                                        borderSide: const BorderSide(
                                            color: AppColors.primary),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Specifications
                      _card(
                        title: 'Specifications',
                        trailing: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _specKeyCtrls.add(TextEditingController());
                              _specValCtrls.add(TextEditingController());
                            });
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: Text('Add',
                              style: GoogleFonts.inter(fontSize: 13)),
                          style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary),
                        ),
                        child: _specKeyCtrls.isEmpty
                            ? Center(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Text('No specifications added yet.',
                                      style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: AppColors.textSecondary)),
                                ),
                              )
                            : Column(
                                children: List.generate(_specKeyCtrls.length, (index) => Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 8),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                    child: _textField(
                                                        controller:
                                                            _specKeyCtrls[index],
                                                        hint: 'Key')),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                    child: _textField(
                                                        controller:
                                                            _specValCtrls[index],
                                                        hint: 'Value')),
                                                IconButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      _specKeyCtrls[index].dispose();
                                                      _specValCtrls[index].dispose();
                                                      _specKeyCtrls.removeAt(index);
                                                      _specValCtrls.removeAt(index);
                                                    });
                                                  },
                                                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                                ),
                                              ],
                                            ),
                                          )),
                              ),
                      ),

                      const SizedBox(height: 16),

                      // Product Variations
                      _card(
                        title: 'Product Variations',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Attributes',
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.textSecondary)),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _attrCheckbox('Size', _sizeAttr,
                                    (v) => setState(
                                        () => _sizeAttr = v!)),
                                const SizedBox(width: 16),
                                _attrCheckbox('Color', _colorAttr,
                                    (v) => setState(
                                        () => _colorAttr = v!)),
                                const SizedBox(width: 16),
                                _attrCheckbox('Material', _materialAttr,
                                    (v) => setState(
                                        () => _materialAttr = v!)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            if (_sizeAttr) ...[
                              _fieldLabel('Size Options'),
                              const SizedBox(height: 8),
                              _textField(controller: _sizeOptionsCtrl, hint: 'e.g., S, M, L, XL'),
                              const SizedBox(height: 4),
                              _infoText('Enter multiple options separated by commas'),
                              const SizedBox(height: 16),
                            ],
                            if (_colorAttr) ...[
                              _fieldLabel('Color Options'),
                              const SizedBox(height: 8),
                              _textField(controller: _colorOptionsCtrl, hint: 'e.g., Red, Blue, Green'),
                              const SizedBox(height: 4),
                              _infoText('Enter multiple options separated by commas'),
                              const SizedBox(height: 16),
                            ],
                            if (_materialAttr) ...[
                              _fieldLabel('Material Options'),
                              const SizedBox(height: 8),
                              _textField(controller: _materialOptionsCtrl, hint: 'e.g., Cotton, Silk, Wool'),
                              const SizedBox(height: 4),
                              _infoText('Enter multiple options separated by commas'),
                              const SizedBox(height: 16),
                            ],
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _generateVariations,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade800,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Generate Variations'),
                              ),
                            ),
                            if (_variations.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              Text('${_variations.length} Variations Found', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 12),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columnSpacing: 20,
                                  horizontalMargin: 0,
                                  columns: [
                                    const DataColumn(label: Text('IMAGE')),
                                    const DataColumn(label: Text('SKU')),
                                    const DataColumn(label: Text('SIZE')),
                                    const DataColumn(label: Text('COLOR')),
                                    const DataColumn(label: Text('MATERIAL')),
                                    const DataColumn(label: Text('PRICE')),
                                    const DataColumn(label: Text('STOCK')),
                                  ],
                                  rows: _variations.asMap().entries.map((entry) {
                                    int idx = entry.key;
                                    var v = entry.value;
                                    return DataRow(cells: [
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (v['image'] != null && v['image'].toString().isNotEmpty) ...[
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(4),
                                                child: Image.network(
                                                  v['image'].toString(),
                                                  width: 32,
                                                  height: 32,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, size: 20),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                            ],
                                            IconButton(
                                              icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                                              onPressed: () => _pickAndUploadVariationImage(idx),
                                              tooltip: 'Upload variation image',
                                            ),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 140,
                                          child: TextField(
                                            decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                                            style: const TextStyle(fontSize: 12),
                                            onChanged: (val) => _variations[idx]['sku'] = val,
                                            controller: TextEditingController(text: v['sku']?.toString() ?? ''),
                                          ),
                                        ),
                                      ),
                                      DataCell(Text(v['size'] ?? '')),
                                      DataCell(Text(v['color'] ?? '')),
                                      DataCell(Text(v['material'] ?? '')),
                                      DataCell(
                                        SizedBox(
                                          width: 80,
                                          child: TextField(
                                            decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                                            style: const TextStyle(fontSize: 12),
                                            keyboardType: TextInputType.number,
                                            onChanged: (val) => _variations[idx]['price'] = double.tryParse(val) ?? 0.0,
                                            controller: TextEditingController(text: v['price'].toString()),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 60,
                                          child: TextField(
                                            decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                                            style: const TextStyle(fontSize: 12),
                                            keyboardType: TextInputType.number,
                                            onChanged: (val) => _variations[idx]['stock'] = int.tryParse(val) ?? 0,
                                            controller: TextEditingController(text: v['stock'].toString()),
                                          ),
                                        ),
                                      ),
                                    ]);
                                  }).toList(),
                              ),
                        )],
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Tags
                      _card(
                        title: 'Tags',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 40,
                                    child: TextField(
                                      controller: _tagCtrl,
                                      style:
                                          GoogleFonts.inter(fontSize: 13),
                                      decoration: InputDecoration(
                                        hintText: 'Add tag',
                                        hintStyle: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: Colors.grey.shade400),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 10),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                              color: Colors.grey.shade300),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                              color: Colors.grey.shade300),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: const BorderSide(
                                              color: AppColors.primary),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      final tag =
                                          _tagCtrl.text.trim();
                                      if (tag.isNotEmpty) {
                                        setState(() {
                                          _tags.add(tag);
                                          _tagCtrl.clear();
                                        });
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                    ),
                                    child: const Icon(Icons.add, size: 20),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (_tags.isEmpty)
                              Text('No tags added yet.',
                                  style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.textSecondary))
                            else
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: _tags
                                    .map((tag) => Chip(
                                          label: Text(tag,
                                              style: GoogleFonts.inter(
                                                  fontSize: 12)),
                                          deleteIcon: const Icon(
                                              Icons.close,
                                              size: 14),
                                          onDeleted: () => setState(
                                              () => _tags.remove(tag)),
                                          backgroundColor:
                                              const Color(0xFFFFF0E6),
                                          labelStyle: GoogleFonts.inter(
                                              color: AppColors.primary),
                                          deleteIconColor:
                                              AppColors.primary,
                                          side: BorderSide.none,
                                        ))
                                    .toList(),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Related Products
                      _card(
                        title: 'Related Products',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select products to show as recommendations',
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  if (_selectedRelatedProductIds.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Text('No related products selected', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey)),
                                    )
                                  else
                                    ..._selectedRelatedProductIds.map((id) {
                                      final product = _allProducts.firstWhere((p) => p['_id'] == id, orElse: () => null);
                                      if (product == null) return const SizedBox.shrink();
                                      return ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                        leading: ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: Image.network(product['image'] ?? '', width: 30, height: 30, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 20)),
                                        ),
                                        title: Text(product['name'] ?? '', style: GoogleFonts.inter(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 18),
                                          onPressed: () {
                                            setState(() {
                                              _selectedRelatedProductIds.remove(id);
                                            });
                                          },
                                        ),
                                      );
                                    }),
                                  const Divider(),
                                  TextButton.icon(
                                    onPressed: () => _showRelatedProductsDialog(),
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Select Products'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRelatedProductsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String searchQuery = "";
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filteredProducts = _allProducts.where((p) {
              final nameMatch = (p['name'] ?? '').toString().toLowerCase().contains(searchQuery.toLowerCase());
              final idMatch = widget.product != null && p['_id'] == widget.product!['_id'];
              return nameMatch && !idMatch;
            }).toList();

            return AlertDialog(
              title: Text('Select Related Products', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: 400,
                height: 500,
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (v) => setDialogState(() => searchQuery = v),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final p = filteredProducts[index];
                          final bool isSelected = _selectedRelatedProductIds.contains(p['_id']);
                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  if (!_selectedRelatedProductIds.contains(p['_id'])) {
                                    _selectedRelatedProductIds.add(p['_id']);
                                  }
                                } else {
                                  _selectedRelatedProductIds.remove(p['_id']);
                                }
                              });
                              setDialogState(() {});
                            },
                            title: Text(p['name'] ?? '', style: GoogleFonts.inter(fontSize: 14)),
                            secondary: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(p['image'] ?? '', width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image)),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
              ],
            );
          },
        );
      },
    );
  }

  // ── Helpers ────────────────────────────────────────────────────

  Widget _card({
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _fieldLabel(String label, {bool required = false}) {
    return RichText(
      text: TextSpan(
        text: label,
        style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary),
        children: required
            ? [
                TextSpan(
                  text: ' *',
                  style:
                      GoogleFonts.inter(color: Colors.red, fontSize: 13),
                )
              ]
            : [],
      ),
    );
  }

Widget _textField({
  required TextEditingController controller,
  required String hint,
  int maxLines = 1,
  TextInputType keyboardType = TextInputType.text,
  List<TextInputFormatter>? inputFormatters, // ADD THIS
}) {
  return TextField(
    controller: controller,
    maxLines: maxLines,
    keyboardType: keyboardType,
    inputFormatters: inputFormatters, // ADD THIS
    style: GoogleFonts.inter(fontSize: 13),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle:
          GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      filled: true,
      fillColor: Colors.white,
    ),
  );
}

  // Widget _textField({
  //   required TextEditingController controller,
  //   required String hint,
  //   int maxLines = 1,
  //   TextInputType keyboardType = TextInputType.text,
  // }) {
  //   return TextField(
  //     controller: controller,
  //     maxLines: maxLines,
  //     keyboardType: keyboardType,
  //     style: GoogleFonts.inter(fontSize: 13),
  //     decoration: InputDecoration(
  //       hintText: hint,
  //       hintStyle:
  //           GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400),
  //       contentPadding:
  //           const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  //       border: OutlineInputBorder(
  //         borderRadius: BorderRadius.circular(8),
  //         borderSide: BorderSide(color: Colors.grey.shade300),
  //       ),
  //       enabledBorder: OutlineInputBorder(
  //         borderRadius: BorderRadius.circular(8),
  //         borderSide: BorderSide(color: Colors.grey.shade300),
  //       ),
  //       focusedBorder: OutlineInputBorder(
  //         borderRadius: BorderRadius.circular(8),
  //         borderSide: const BorderSide(color: AppColors.primary),
  //       ),
  //       filled: true,
  //       fillColor: Colors.white,
  //     ),
  //   );
  // }



  Widget _dropdownField({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: Colors.white,
          hint: Text(hint,
              style: GoogleFonts.inter(
                  fontSize: 13, color: Colors.grey.shade400)),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          style:
              GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
          items: items
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _uploadBox({
    required double width,
    required double height,
    required String? label,
    XFile? imageFile,
    String? imageUrl,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          border: Border.all(
              color: Colors.grey.shade300,
              style: BorderStyle.solid,
              width: 1.5),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade50,
        ),
        child: imageFile != null
            ? (kIsWeb 
                ? Image.network(imageFile.path, fit: BoxFit.cover)
                : Image.file(io.File(imageFile.path), fit: BoxFit.cover))
            : imageUrl != null
            ? Image.network(imageUrl, fit: BoxFit.cover)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.upload_outlined,
                      size: 24, color: Colors.grey.shade400),
                  if (label != null) ...[
                    const SizedBox(height: 4),
                    Text(label,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 6,
              height: 6,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _infoText(String text) {
    return Row(
      children: [
        Icon(Icons.info_outline, size: 13, color: Colors.blue.shade400),
        const SizedBox(width: 4),
        Text(text,
            style: GoogleFonts.inter(
                fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }



  Widget _attrCheckbox(
      String label, bool value, ValueChanged<bool?> onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: Checkbox(
            value: value,
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.textPrimary)),
      ],
    );
  }
  Widget _selectionField({
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: Colors.white,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
          items: options.map((String option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
