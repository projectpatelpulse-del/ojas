part of 'add_product_page.dart';

extension AddProductPricingMedia on _AddProductPageState {
  Widget _buildPricingCard() {
    final bool hasVariations = _variations.isNotEmpty;
    return _card(
      title: 'Pricing',
      note: hasVariations ? "Note: Product has variations. Main price fields are disabled. Please set price/stock inside each variation below." : null,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Regular Price', required: !hasVariations),
                    const SizedBox(height: 6),
                    _textField(
                        controller: _regularPriceCtrl,
                        hint: '0.00',
                        enabled: !hasVariations,
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
                    _fieldLabel('Discount (%)'),
                    const SizedBox(height: 6),
                    _textField(
                        controller: _discountedPriceCtrl,
                        hint: 'e.g. 10',
                        keyboardType: TextInputType.number,
                        onChanged: (_) => updateState(() {
                          _recalculateVariationPrices();
                        })),
                    if ((double.tryParse(_regularPriceCtrl.text) ?? 0) > 0 &&
                        (double.tryParse(_discountedPriceCtrl.text) ?? 0) > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Selling Price: ₹${((double.tryParse(_regularPriceCtrl.text) ?? 0) * (1 - (double.tryParse(_discountedPriceCtrl.text) ?? 0) / 100)).toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
    );
  }

  Widget _buildMediaCard() {
    return _card(
      note: "Kindly Upload Main Image In White Background",
      title: 'Main Image',
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
                      updateState(() {
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
                    const SizedBox(height: 4),

          _fieldLabel('Gallery Images'),
          const SizedBox(height: 4),
          // Row(
          //   crossAxisAlignment: CrossAxisAlignment.start,
          //   children: [
          //     const Icon(
          //       Icons.info_outline,
          //       size: 14,
          //       color: AppColors.warning,
          //     ),
              // const SizedBox(width: 6),
              // Expanded(
              //   child: Text(
              //     'Note: 1st gallery image must be the Size Guide, and 2nd image must be the Packaging Box.',
              //     style: GoogleFonts.inter(
              //       fontSize: 12,
              //       color: AppColors.warning,
              //       fontWeight: FontWeight.w500,
              //     ),
              //   ),
              // ),
          //   ],
          // ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ..._galleryUrls.asMap().entries.map((entry) {
                final int idx = entry.key;
                final String url = entry.value;
                String? overlayLabel;
                if (idx == 0) {
                  overlayLabel = 'Size Guide';
                } else if (idx == 1) {
                  overlayLabel = 'Packaging Box';
                }
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _uploadBox(
                      width: 100,
                      height: 80,
                      label: null,
                      imageUrl: url,
                      onTap: () {},
                    ),
                    if (overlayLabel != null)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            overlayLabel,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      right: -6,
                      top: -6,
                      child: GestureDetector(
                        onTap: () {
                          updateState(() {
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
                );
              }),
              ..._galleryImages.asMap().entries.map((entry) {
                final int idx = _galleryUrls.length + entry.key;
                final XFile file = entry.value;
                String? overlayLabel;
                if (idx == 0) {
                  overlayLabel = 'Size Guide';
                } else if (idx == 1) {
                  overlayLabel = 'Packaging Box';
                }
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _uploadBox(
                      width: 100,
                      height: 80,
                      label: null,
                      imageFile: file,
                      onTap: () {},
                    ),
                    if (overlayLabel != null)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            overlayLabel,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      right: -6,
                      top: -6,
                      child: GestureDetector(
                        onTap: () {
                          updateState(() {
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
                );
              }),
              _uploadBox(
                width: 100, 
                height: 80, 
                label: (_galleryUrls.length + _galleryImages.length) == 0
                    ? '1st: Size Guide'
                    : (_galleryUrls.length + _galleryImages.length) == 1
                        ? '2nd: Packaging'
                        : 'Add Image',
                onTap: _pickGalleryImage,
              ),
            ],
          ),
          // const SizedBox(height: 16),
          // // _fieldLabel('YouTube Video Link (optional)'),
          // const SizedBox(height: 6),
          // _textField(
          //     controller: _youtubeCtrl,
          //     hint: 'https://www.youtube.com/watch?v=...'),
       
        ],
      ),
    );
  }

  Widget _buildShippingCard() {
    return _card(
      title: 'Shipping',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('Weight (Max 5kg)'),
          const SizedBox(height: 6),
          _textField(
              controller: _weightCtrl,
              hint: '0.5',
              keyboardType: TextInputType.number),
          const SizedBox(height: 14),
          _fieldLabel('Dimensions (Max 100 cm)'),
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
                  onChanged: (v) => updateState(
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
    );
  }

  Widget _buildSEOCard() {
    return _card(
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
          // _fieldLabel('URL Slug'),
          // const SizedBox(height: 6),
          // Row(
          //   children: [
          //     Container(
          //       padding: const EdgeInsets.symmetric(
          //           horizontal: 10, vertical: 12),
          //       decoration: BoxDecoration(
          //         color: Colors.grey.shade100,
          //         border: Border.all(
          //             color: Colors.grey.shade300),
          //         borderRadius: const BorderRadius.only(
          //           topLeft: Radius.circular(8),
          //           bottomLeft: Radius.circular(8),
          //         ),
          //       ),
          //       child: Text('yourstore.com/products/',
          //           style: GoogleFonts.inter(
          //               fontSize: 12,
          //               color: AppColors.textSecondary)),
          //     ),
          //     Expanded(
          //       child: TextField(
          //         controller: _slugCtrl,
          //         style:
          //             GoogleFonts.inter(fontSize: 13),
          //         decoration: InputDecoration(
          //           hintText: 'product-name',
          //           hintStyle: GoogleFonts.inter(
          //               fontSize: 13,
          //               color: Colors.grey.shade400),
          //           contentPadding:
          //               const EdgeInsets.symmetric(
          //                   horizontal: 10, vertical: 12),
          //           border: OutlineInputBorder(
          //             borderRadius:
          //                 const BorderRadius.only(
          //               topRight: Radius.circular(8),
          //               bottomRight: Radius.circular(8),
          //             ),
          //             borderSide: BorderSide(
          //                 color: Colors.grey.shade300),
          //           ),
          //           enabledBorder: OutlineInputBorder(
          //             borderRadius:
          //                 const BorderRadius.only(
          //               topRight: Radius.circular(8),
          //               bottomRight: Radius.circular(8),
          //             ),
          //             borderSide: BorderSide(
          //                 color: Colors.grey.shade300),
          //           ),
          //           focusedBorder: OutlineInputBorder(
          //             borderRadius:
          //                 const BorderRadius.only(
          //               topRight: Radius.circular(8),
          //               bottomRight: Radius.circular(8),
          //             ),
          //             borderSide: const BorderSide(
          //                 color: AppColors.primary),
          //           ),
          //         ),
          //       ),
          //     ),
          //   ],
          // ),
      
        ],
      ),
    );
  }

  Widget _buildStatusAndVisibilityCard() {
    return _card(
      title: 'Status & Visibility',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('Product Status'),
          const SizedBox(height: 8),
          _selectionField(
            value: _productStatus,
            options: ['Draft', 'Active', 'Archived'],
            onChanged: (v) => updateState(() => _productStatus = v!),
          ),
          const SizedBox(height: 16),
          _fieldLabel('Visibility'),
          const SizedBox(height: 8),
          _selectionField(
            value: _visibility,
            options: ['Public', 'Private', 'Password Protected'],
            onChanged: (v) => updateState(() => _visibility = v!),
          ),
          const SizedBox(height: 24),
          _fieldLabel('Show on Pages'),
          const SizedBox(height: 8),
          Column(
            children: ['Home', 'Features', 'Deals', 'Shop', 'Trending', 'Daily Deals', 'Just For You', 'Latest Products'].map((page) {
              return Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _showOnPages.contains(page),
                      activeColor: AppColors.primary,
                      onChanged: (v) {
                        updateState(() {
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
    );
  }

  Widget _buildInventoryCard() {
    return _card(
      title: 'Inventory',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _fieldLabel('SKU (Stock Keeping Unit)', required: true)),
              TextButton.icon(
                onPressed: () {
                  updateState(() {
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
          _fieldLabel('Quantity', required: true),
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
          // const SizedBox(height: 14),
          // _fieldLabel('MOQ Additional Discount (%)'),
          // const SizedBox(height: 6),
          // _textField(
          //     controller: _moqDiscountCtrl,
          //     hint: '0',
          //     keyboardType: TextInputType.number),
          
          const SizedBox(height: 14),
          _fieldLabel('Additional Quantity Discount (Format: qty:discount%, qty:discount%)'),
          const SizedBox(height: 6),
          _textField(
              controller: _moqTiersCtrl,
              hint: '10:5%, 20:7%, 50:10%'),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: _trackQuantity,
                  activeColor: AppColors.primary,
                  onChanged: (v) => updateState(
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
    );
  }

  Widget _buildTagsCard() {
    return _card(
      title: 'Keywords',
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
                      hintText: 'Add Keyword',
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
                      updateState(() {
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
            Text('No Keywords added yet.',
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
                        onDeleted: () => updateState(
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
    );
  }

  Widget _buildRelatedProductsCard() {
    return _card(
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
                          updateState(() {
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
    );
  }
}
