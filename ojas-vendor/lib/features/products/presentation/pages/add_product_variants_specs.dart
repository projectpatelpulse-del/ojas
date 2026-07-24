part of 'add_product_page.dart';

extension AddProductVariantsSpecs on _AddProductPageState {
  Widget _buildSpecificationsCard() {
    return _card(
      title: 'Specifications',
      required: true,
      trailing: TextButton.icon(
        onPressed: () {
          updateState(() {
            _specKeyCtrls.add(TextEditingController());
            _specValCtrls.add(TextEditingController());
          });
        },
        icon: const Icon(Icons.add, size: 16),
        label: Text('Add Custom Spec',
            style: GoogleFonts.inter(fontSize: 13)),
        style: TextButton.styleFrom(
            foregroundColor: AppColors.primary),
      ),
      child: _specKeyCtrls.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('No specifications added yet.',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary)),
              ),
            )
          : Wrap(
              spacing: 16,
              runSpacing: 16,
              children: List.generate(_specKeyCtrls.length, (index) {
                final String specTextNormalized = _specKeyCtrls[index].text.trim().replaceAll(' *', '').toLowerCase();
                final bool isRequiredSpec = [
                  'size',
                  'weight',
                  'colour',
                  'color',
                  'care instructions',
                  'care instruction',
                  'basic metal'
                ].contains(specTextNormalized);

                return SizedBox(
                  width: 420,
                  child: Row(
                    children: [
                      Expanded(
                        child: isRequiredSpec
                            ? Container(
                                height: 48,
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey.shade50,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _specKeyCtrls[index].text,
                                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      '*',
                                      style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              )
                            : _textField(
                                controller: _specKeyCtrls[index],
                                hint: 'Key',
                              ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _textField(
                          controller: _specValCtrls[index],
                          hint: 'Value',
                        ),
                      ),
                      if (!isRequiredSpec)
                        IconButton(
                          onPressed: () {
                            updateState(() {
                              _specKeyCtrls[index].dispose();
                              _specValCtrls[index].dispose();
                              _specKeyCtrls.removeAt(index);
                              _specValCtrls.removeAt(index);
                            });
                          },
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        )
                      else
                        const SizedBox(width: 48), // Keep alignment matching delete button width
                    ],
                  ),
                );
              }),
            ),
    );
  }

  Widget _buildVariationsCard() {
    return _card(
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
                  (v) => updateState(
                      () => _sizeAttr = v!)),
              const SizedBox(width: 24),
              _attrCheckbox('Color', _colorAttr,
                  (v) => updateState(
                      () => _colorAttr = v!)),
              const SizedBox(width: 24),
              _attrCheckbox('Material', _materialAttr,
                  (v) => updateState(
                      () => _materialAttr = v!)),
              const SizedBox(width: 24),
              _attrCheckbox('Weight', _weightAttr,
                  (v) => updateState(
                      () => _weightAttr = v!)),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              if (_sizeAttr)
                SizedBox(
                  width: 280,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('Size Options '),
                      // (Max 100 cm)'),
                      const SizedBox(height: 8),
                      _textField(controller: _sizeOptionsCtrl, hint: 'e.g., S, M, L, XL'),
                      const SizedBox(height: 4),
                      _infoText('Enter multiple options separated by commas'),
                    ],
                  ),
                ),
              if (_colorAttr)
                SizedBox(
                  width: 280,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('Color Options'),
                      const SizedBox(height: 8),
                      _textField(controller: _colorOptionsCtrl, hint: 'e.g., Red, Blue, Green'),
                      const SizedBox(height: 4),
                      _infoText('Enter multiple options separated by commas'),
                    ],
                  ),
                ),
              if (_materialAttr)
                SizedBox(
                  width: 280,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('Material Options'),
                      const SizedBox(height: 8),
                      _textField(controller: _materialOptionsCtrl, hint: 'e.g., Cotton, Silk, Wool'),
                      const SizedBox(height: 4),
                      _infoText('Enter multiple options separated by commas'),
                    ],
                  ),
                ),
              if (_weightAttr)
                SizedBox(
                  width: 280,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('Weight Options'),
                      // (Max 5kg)'),
                      const SizedBox(height: 8),
                      _textField(controller: _weightOptionsCtrl, hint: 'e.g., 100g, 250g, 500g'),
                      const SizedBox(height: 4),
                      _infoText('Enter multiple options separated by commas'),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _generateVariations,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade800,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Generate Variations', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ),
          if (_variations.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_variations.length} Variations Found', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, size: 16, color: AppColors.primary),
                      onPressed: () {
                        if (_variationScrollController.hasClients) {
                          _variationScrollController.animateTo(
                            (_variationScrollController.offset - 200).clamp(0.0, _variationScrollController.position.maxScrollExtent),
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      tooltip: 'Scroll Left',
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.primary),
                      onPressed: () {
                        if (_variationScrollController.hasClients) {
                          _variationScrollController.animateTo(
                            (_variationScrollController.offset + 200).clamp(0.0, _variationScrollController.position.maxScrollExtent),
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      tooltip: 'Scroll Right',
                    ),
                    const SizedBox(width: 8),
                    Checkbox(
                      value: _syncVariationDetails,
                      onChanged: (v) {
                        updateState(() {
                          _syncVariationDetails = v ?? false;
                          if (_syncVariationDetails && _variations.isNotEmpty) {
                            final firstPrice = _variations[0]['price'];
                            final firstStock = _variations[0]['stock'];
                            final firstImage = _variations[0]['image'];
                            final firstImages = _variations[0]['images'];
                            for (var i = 0; i < _variations.length; i++) {
                              _variations[i]['price'] = firstPrice;
                              _variations[i]['stock'] = firstStock;
                              _variations[i]['image'] = firstImage;
                              _variations[i]['images'] = firstImages;
                            }
                          }
                        });
                      },
                    ),
                    Text('Keep price, stock, and images same for all variations', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Scrollbar(
              controller: _variationScrollController,
              thumbVisibility: true,
              trackVisibility: true,
              child: SingleChildScrollView(
                controller: _variationScrollController,
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: DataTable(
                columnSpacing: 40,
                horizontalMargin: 8,
                columns: [
                  const DataColumn(label: Text('IMAGES (MAX 3)')),
                  const DataColumn(label: Text('TITLE')),
                  const DataColumn(label: Text('SKU')),
                  const DataColumn(label: Text('SIZE')),
                  const DataColumn(label: Text('COLOR')),
                  const DataColumn(label: Text('MATERIAL')),
                  const DataColumn(label: Text('WEIGHT')),
                  const DataColumn(label: Text('SELLING PRICE')),
                  const DataColumn(label: Text('MRP')),
                  const DataColumn(label: Text('STOCK')),
                  const DataColumn(label: Text('ACTIONS')),
                ],
                rows: _variations.asMap().entries.map((entry) {
                  int idx = entry.key;
                  var v = entry.value;
                  return DataRow(cells: [
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(3, (imgIdx) {
                          List<String> imgs = [];
                          if (v['images'] != null && (v['images'] as List).isNotEmpty) {
                            imgs = List<String>.from(v['images']);
                          } else if (v['image'] != null && v['image'].toString().isNotEmpty) {
                            imgs = [v['image'].toString()];
                          }
                          final String url = imgs.length > imgIdx ? imgs[imgIdx] : '';
                          final bool hasImage = url.isNotEmpty;

                          return Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(4),
                                    color: Colors.grey.shade50,
                                  ),
                                  child: hasImage
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: Image.network(
                                            url,
                                            width: 36,
                                            height: 36,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                const Icon(Icons.error, size: 14),
                                          ),
                                        )
                                      : IconButton(
                                          padding: EdgeInsets.zero,
                                          icon: const Icon(Icons.add_a_photo_outlined, size: 14),
                                          onPressed: () => _pickAndUploadVariationImage(idx, imgIdx),
                                          tooltip: 'Upload image ${imgIdx + 1}',
                                        ),
                                ),
                                if (hasImage)
                                  Positioned(
                                    right: -4,
                                    top: -4,
                                    child: GestureDetector(
                                      onTap: () {
                                        updateState(() {
                                          List<String> updated = [];
                                          if (v['images'] != null && (v['images'] as List).isNotEmpty) {
                                            updated = List<String>.from(v['images']);
                                          } else if (v['image'] != null && v['image'].toString().isNotEmpty) {
                                            updated = [v['image'].toString()];
                                          }
                                          while (updated.length <= imgIdx) {
                                            updated.add('');
                                          }
                                          updated[imgIdx] = '';
                                          v['images'] = updated;
                                          if (imgIdx == 0) {
                                            v['image'] = '';
                                          }
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, size: 8, color: Colors.white),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 150,
                        child: TextField(
                          decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                          style: const TextStyle(fontSize: 13),
                          onChanged: (val) => _variations[idx]['title'] = val,
                          controller: _variationTitleCtrls[idx],
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 180,
                        child: TextField(
                          decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                          style: const TextStyle(fontSize: 13),
                          onChanged: (val) => _variations[idx]['sku'] = val,
                          controller: _variationSkuCtrls[idx],
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 80,
                        child: TextField(
                          decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                          style: const TextStyle(fontSize: 13),
                          onChanged: (val) => _variations[idx]['size'] = val,
                          controller: _variationSizeCtrls[idx],
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 100,
                        child: TextField(
                          decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                          style: const TextStyle(fontSize: 13),
                          onChanged: (val) => _variations[idx]['color'] = val,
                          controller: _variationColorCtrls[idx],
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 100,
                        child: TextField(
                          decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                          style: const TextStyle(fontSize: 13),
                          onChanged: (val) => _variations[idx]['material'] = val,
                          controller: _variationMaterialCtrls[idx],
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 80,
                        child: TextField(
                          decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                          style: const TextStyle(fontSize: 13),
                          onChanged: (val) => _variations[idx]['weight'] = val,
                          controller: _variationWeightCtrls[idx],
                        ),
                      ),
                    ),
                     DataCell(
                      SizedBox(
                        width: 100,
                        child: TextField(
                          decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                          style: const TextStyle(fontSize: 13),
                          keyboardType: TextInputType.number,
                          enabled: (double.tryParse(_discountedPriceCtrl.text) ?? 0.0) <= 0,
                          onChanged: (val) {
                            final parsedPrice = double.tryParse(val) ?? 0.0;
                            updateState(() {
                              if (_syncVariationDetails) {
                                for (var i = 0; i < _variations.length; i++) {
                                  _variations[i]['price'] = parsedPrice;
                                  if (i != idx) {
                                    _variationPriceCtrls[i].text = val;
                                  }
                                }
                              } else {
                                _variations[idx]['price'] = parsedPrice;
                              }
                            });
                          },
                          controller: _variationPriceCtrls[idx],
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 100,
                        child: TextField(
                          decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                          style: const TextStyle(fontSize: 13),
                          keyboardType: TextInputType.number,
                          onChanged: (val) {
                            final parsedOldPrice = double.tryParse(val) ?? 0.0;
                            final discountPercent = double.tryParse(_discountedPriceCtrl.text) ?? 0.0;
                            updateState(() {
                              if (_syncVariationDetails) {
                                for (var i = 0; i < _variations.length; i++) {
                                  _variations[i]['oldPrice'] = parsedOldPrice;
                                  if (i != idx) {
                                    _variationOldPriceCtrls[i].text = val;
                                  }
                                  final double computedPrice = discountPercent > 0
                                      ? parsedOldPrice * (1 - discountPercent / 100)
                                      : parsedOldPrice;
                                  _variations[i]['price'] = computedPrice;
                                  _variationPriceCtrls[i].text = computedPrice.toStringAsFixed(2);
                                }
                              } else {
                                _variations[idx]['oldPrice'] = parsedOldPrice;
                                final double computedPrice = discountPercent > 0
                                    ? parsedOldPrice * (1 - discountPercent / 100)
                                    : parsedOldPrice;
                                _variations[idx]['price'] = computedPrice;
                                _variationPriceCtrls[idx].text = computedPrice.toStringAsFixed(2);
                              }
                            });
                          },
                          controller: _variationOldPriceCtrls[idx],
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 80,
                        child: TextField(
                          decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                          style: const TextStyle(fontSize: 13),
                          keyboardType: TextInputType.number,
                          onChanged: (val) {
                            final parsedStock = int.tryParse(val) ?? 0;
                            updateState(() {
                              if (_syncVariationDetails) {
                                for (var i = 0; i < _variations.length; i++) {
                                  _variations[i]['stock'] = parsedStock;
                                  if (i != idx) {
                                    _variationStockCtrls[i].text = val;
                                  }
                                }
                              } else {
                                _variations[idx]['stock'] = parsedStock;
                              }
                            });
                          },
                          controller: _variationStockCtrls[idx],
                        ),
                      ),
                    ),
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          updateState(() {
                            _variations.removeAt(idx);
                            _syncVariationControllers();
                          });
                        },
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ),
      ],
        ],
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
                              updateState(() {
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
}
