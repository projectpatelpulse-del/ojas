import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_user/core/constants/app_colors.dart';
import 'package:ojas_user/core/controllers/home_controller.dart';
import 'package:ojas_user/core/services/api_service.dart';
import 'package:ojas_user/features/home/domain/models/product_model.dart';

class SmartSearchBar extends StatefulWidget {
  final bool isMobile;
  final String hintText;

  const SmartSearchBar({
    super.key,
    this.isMobile = false,
    this.hintText = 'Search products, categories, variations...',
  });

  @override
  State<SmartSearchBar> createState() => _SmartSearchBarState();
}

class _SmartSearchBarState extends State<SmartSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  List<Map<String, dynamic>> _matchingCategories = [];
  List<Map<String, dynamic>> _matchingProducts = [];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _controller.text.trim().isNotEmpty) {
        _updateSuggestions(_controller.text.trim());
      }
    });
  }

  @override
  void dispose() {
    _hideOverlay();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _hideOverlay();
    } else {
      _updateSuggestions(trimmed);
    }
  }

  void _updateSuggestions(String query) {
    final lower = query.toLowerCase();

    // 1. Match Categories
    final allCategories = HomeController.instance.categories;
    final matchedCats = allCategories.where((cat) {
      final name = (cat['name'] ?? '').toString().toLowerCase();
      return name.contains(lower);
    }).take(4).map((c) => Map<String, dynamic>.from(c)).toList();

    // 2. Match Products & Variations
    final allProducts = HomeController.instance.products.isNotEmpty 
        ? HomeController.instance.products 
        : HomeController.instance.shopProducts;

    final matchedProds = <Map<String, dynamic>>[];

    for (var p in allProducts) {
      if (matchedProds.length >= 6) break;

      final name = (p['name'] ?? '').toString().toLowerCase();
      final brand = (p['brand'] ?? '').toString().toLowerCase();
      
      String catName = '';
      if (p['category'] is Map) {
        catName = (p['category']['name'] ?? '').toString().toLowerCase();
      } else if (p['category'] != null) {
        catName = p['category'].toString().toLowerCase();
      }

      bool nameOrCatMatch = name.contains(lower) || brand.contains(lower) || catName.contains(lower);
      String matchedVarLabel = '';

      // Check variations
      final variations = p['variations'];
      if (variations is List) {
        for (var v in variations) {
          if (v is Map) {
            final color = (v['color'] ?? '').toString().toLowerCase();
            final model = (v['modelName'] ?? '').toString().toLowerCase();
            final material = (v['material'] ?? '').toString().toLowerCase();
            final weight = (v['weightStr'] ?? v['weight'] ?? '').toString().toLowerCase();
            final title = (v['title'] ?? '').toString().toLowerCase();

            if (color.contains(lower) || model.contains(lower) || material.contains(lower) || weight.contains(lower) || title.contains(lower)) {
              matchedVarLabel = [
                if (v['modelName'] != null && v['modelName'].toString().isNotEmpty) v['modelName'],
                if (v['color'] != null && v['color'].toString().isNotEmpty) v['color'],
                if (v['material'] != null && v['material'].toString().isNotEmpty) v['material'],
              ].join(' / ');
              break;
            }
          }
        }
      }

      if (nameOrCatMatch || matchedVarLabel.isNotEmpty) {
        final prodCopy = Map<String, dynamic>.from(p);
        if (matchedVarLabel.isNotEmpty) {
          prodCopy['matchedVariation'] = matchedVarLabel;
        }
        matchedProds.add(prodCopy);
      }
    }

    setState(() {
      _matchingCategories = matchedCats;
      _matchingProducts = matchedProds;
    });

    if (_matchingCategories.isNotEmpty || _matchingProducts.isNotEmpty) {
      _showOverlay();
    } else {
      _hideOverlay();
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
      return;
    }

    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (overlayContext) => Positioned(
        width: widget.isMobile ? MediaQuery.of(context).size.width - 32 : 550,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 50),
          child: TapRegion(
            groupId: this,
            child: Material(
              elevation: 12,
              borderRadius: BorderRadius.circular(12),
              color: AppColors.white,
              shadowColor: Colors.black26,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 420),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Categories Section
                      if (_matchingCategories.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
                          child: Text(
                            'CATEGORIES',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: _matchingCategories.map((cat) {
                              final name = cat['name'] ?? '';
                              return ActionChip(
                                label: Text(
                                  name,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                avatar: const Icon(
                                  Icons.category_outlined,
                                  size: 14,
                                  color: AppColors.primaryPink,
                                ),
                                backgroundColor: const Color(0xFFF8FAFC),
                                side: const BorderSide(color: Color(0xFFE2E8F0)),
                                onPressed: () => _navigateToCategory(name),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      ],

                      // Products Section
                      if (_matchingProducts.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                          child: Text(
                            'PRODUCTS & VARIATIONS',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                        ..._matchingProducts.map((p) {
                          final name = p['name'] ?? '';
                          final num priceNum = (p['discountPrice'] != null && p['discountPrice'] > 0)
                              ? p['discountPrice']
                              : (p['price'] ?? 0);
                          final int displayPrice = (num.tryParse(priceNum.toString()) ?? 0).ceil();
                          final images = p['images'];
                          final String rawImg = (images is List && images.isNotEmpty)
                              ? images[0].toString()
                              : (p['image']?.toString() ?? '');
                          final String imgUrl = rawImg.isNotEmpty
                              ? ApiService.formatImageUrl(rawImg)
                              : 'https://via.placeholder.com/80';
                          final String? matchedVar = p['matchedVariation'];

                          return InkWell(
                            onTap: () => _navigateToProduct(p),
                            hoverColor: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.network(
                                      imgUrl,
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, err, stack) => Container(
                                        width: 44,
                                        height: 44,
                                        color: const Color(0xFFF1F5F9),
                                        child: const Icon(
                                          Icons.image_not_supported_outlined,
                                          size: 20,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: const Color(0xFF0F172A),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (matchedVar != null && matchedVar.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEFF6FF),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: const Color(0xFFBFDBFE)),
                                            ),
                                            child: Text(
                                              'Variation: $matchedVar',
                                              style: GoogleFonts.inter(
                                                fontSize: 10,
                                                color: const Color(0xFF1D4ED8),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '₹$displayPrice',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],

                      // View all results footer
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      InkWell(
                        onTap: _submitSearch,
                        hoverColor: const Color(0xFFF8FAFC),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Search for "${_controller.text.trim()}"',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.primaryPink,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.primaryPink),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _navigateToProduct(Map<String, dynamic> p) {
    _hideOverlay();
    _focusNode.unfocus();

    if (!mounted) return;

    final id = (p['_id'] ?? p['id'] ?? '').toString();
    ProductModel? productModel;
    try {
      productModel = ProductModel.fromMap(Map<String, dynamic>.from(p));
    } catch (e, stack) {
      debugPrint('Error converting product to ProductModel: $e\n$stack');
    }

    final String refSuffix = (productModel?.resellerCode != null && productModel!.resellerCode!.isNotEmpty)
        ? '&ref=${productModel.resellerCode}'
        : '';

    Navigator.of(context).pushNamed(
      '/product-detail?id=$id$refSuffix',
      arguments: productModel,
    );
  }

  void _navigateToCategory(String name) {
    _hideOverlay();
    _focusNode.unfocus();

    if (!mounted) return;

    Navigator.of(context).pushNamed(
      '/shop',
      arguments: {'category': name},
    );
  }

  void _submitSearch() {
    final query = _controller.text.trim();
    if (query.isNotEmpty) {
      _hideOverlay();
      _focusNode.unfocus();

      if (!mounted) return;

      Navigator.of(context).pushNamed(
        '/shop',
        arguments: {'search': query},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      groupId: this,
      onTapOutside: (_) {
        _hideOverlay();
      },
      child: CompositedTransformTarget(
        link: _layerLink,
        child: Container(
          height: 45,
          decoration: BoxDecoration(
            color: widget.isMobile ? AppColors.white : const Color(0xFFE2DFD8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.goldAccent,
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    onChanged: _onQueryChanged,
                    onSubmitted: (_) => _submitSearch(),
                    style: const TextStyle(color: AppColors.black, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      hintStyle: const TextStyle(
                        color: AppColors.grey600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
              if (_controller.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close, size: 16, color: AppColors.grey),
                  onPressed: () {
                    _controller.clear();
                    _hideOverlay();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              InkWell(
                onTap: _submitSearch,
                child: Container(
                  width: 45,
                  height: 45,
                  decoration: const BoxDecoration(
                    color: AppColors.goldAccent,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(6),
                      bottomRight: Radius.circular(6),
                    ),
                  ),
                  child: const Icon(
                    Icons.search,
                    color: AppColors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
