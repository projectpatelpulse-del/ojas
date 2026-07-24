part of 'add_product_page.dart';

extension AddProductBasicInfo on _AddProductPageState {
  Widget _buildBasicInfoCard() {
    return _card(
      title: 'Basic Information',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('Display Title', required: true),
          const SizedBox(height: 6),
          _textField(
            controller: _productNameCtrl,
            hint: 'e.g. Premium Silk Scarf',
          ),
          const SizedBox(height: 16),
          _fieldLabel('Package Includes', required: true),
          const SizedBox(height: 6),
          _textField(
            controller: _shortDescCtrl,
            hint: 'A quick summary (1-2 sentences)',
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: [
          //     _fieldLabel('Full Description'),
          //     Row(
          //       mainAxisSize: MainAxisSize.min,
          //       children: [
          //         Checkbox(
          //           value: _autoBulletMode,
          //           activeColor: AppColors.primary,
          //           onChanged: (v) {
          //             updateState(() {
          //               _autoBulletMode = v ?? false;
          //             });
          //           },
          //         ),
          //         Text(
          //           'Bullet',
          //           style: GoogleFonts.inter(
          //             fontSize: 12,
          //             fontWeight: FontWeight.w500,
          //             color: AppColors.textSecondary,
          //           ),
          //         ),
          //         // const SizedBox(width: 12),
          //         // OutlinedButton(
          //         //   onPressed: () {
          //         //     final text = _fullDescCtrl.text;
          //         //     if (text.isEmpty) {
          //         //       _fullDescCtrl.text = "• ";
          //         //     } else {
          //         //       final lines = text.split('\n');
          //         //       final updatedLines = lines.map((line) {
          //         //         final trimmed = line.trim();
          //         //         if (trimmed.isEmpty) return line;
          //         //         if (trimmed.startsWith('•') ||
          //         //             trimmed.startsWith('-') ||
          //         //             trimmed.startsWith('*') ||
          //         //             trimmed.startsWith('o')) {
          //         //           return line;
          //         //         }
          //         //         return "• $line";
          //         //       }).toList();
          //         //       _fullDescCtrl.text = updatedLines.join('\n');
          //         //     }
          //         //     updateState(() {
          //         //       _autoBulletMode = true;
          //         //     });
          //         //     _fullDescCtrl.selection = TextSelection.fromPosition(
          //         //       TextPosition(offset: _fullDescCtrl.text.length),
          //         //     );
          //         //   },
          //         //   // icon: const Icon(Icons.format_list_bulleted, size: 16),
          //         //   // label: const Text("Bullet"),
          //         //   // child: const Icon(Icons.format_list_bulleted, size: 16),
          //         //   style: OutlinedButton.styleFrom(
          //         //     padding: const EdgeInsets.symmetric(
          //         //         horizontal: 12, vertical: 8),
          //         //     shape: RoundedRectangleBorder(
          //         //       borderRadius: BorderRadius.circular(6),
          //         //     ),
          //         //   ),
          //         // ),
          //       ],
          //     ),
          //   ],
          // ),
          _fieldLabel('Full Description'),
          const SizedBox(height: 6),
          _textField(
            controller: _fullDescCtrl,
            hint: 'Detailed product details, features, and story',
            maxLines: 6,
            keyboardType: TextInputType.multiline,
          ),
          const SizedBox(height: 8),
          _infoText(
            'Tip: Write each bullet point on a new line (e.g. • High quality cotton).',
          ),
          const SizedBox(height: 16),
          _fieldLabel('Category', required: true),
          const SizedBox(height: 6),
          _dropdownField(
            value: _selectedCategory,
            hint: 'Select category',
            items: _categories.map((c) => c['name'].toString()).toList(),
            onChanged: (v) {
              updateState(() {
                _selectedCategory = v;
                _selectedSubCategory = null;
                final selectedCat = _categories.firstWhere(
                  (c) => c['name'] == v,
                );
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
            onChanged: (v) => updateState(() => _selectedSubCategory = v),
          ),
        ],
      ),
    );
  }
}
