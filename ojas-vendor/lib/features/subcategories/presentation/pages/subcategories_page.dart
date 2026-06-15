import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_vendor/core/constants/app_colors.dart';
import 'package:ojas_vendor/core/widgets/sidebar_layout.dart';
import 'package:ojas_vendor/core/widgets/vendor_topbar.dart';
import 'package:ojas_vendor/core/services/api_service.dart';

class SubcategoriesPage extends StatefulWidget {
  const SubcategoriesPage({super.key});

  @override
  State<SubcategoriesPage> createState() => _SubcategoriesPageState();
}

class _SubcategoriesPageState extends State<SubcategoriesPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<dynamic> _subCategories = [];
  List<dynamic> _categories = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final subResponse = await ApiService().dio.get('/vendor/subcategory');
      final catResponse = await ApiService().dio.get('/vendor/category');
      
      if (mounted) {
        setState(() {
          _subCategories = subResponse.data['data'] ?? [];
          _categories = catResponse.data['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteSubCategory(String id) async {
    try {
      await ApiService().dio.delete('/vendor/subcategory/$id');
      _fetchData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subcategory deleted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SidebarLayout(
      activeRoute: '/subcategories',
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: const VendorTopBar(),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sub Categories',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manage product sub-categories. ${_subCategories.length} active sub-categories.',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAddSubcategoryDialog,
                    icon: const Icon(Icons.add, size: 20),
                    label: Text(
                      'Add Sub Category',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Stats Row
              Row(
                children: [
                  _buildStatCard('Total Sub Categories', '${_subCategories.length}', AppColors.textPrimary),
                  const SizedBox(width: 24),
                  _buildStatCard('Active Sub Categories', '${_subCategories.where((s) => s['status'] == 'active').length}', AppColors.success),
                  const SizedBox(width: 24),
                  _buildStatCard(
                    'System Sub-Cats', 
                    '${_subCategories.where((s) => s['user'] == "000000000000000000000000").length}', 
                    AppColors.info
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Filter and Search Bar
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search sub-categories...',
                                  hintStyle: GoogleFonts.inter(
                                    color: Colors.grey.shade400,
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: 'All Parent Categories',
                          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                          items: ['All Parent Categories'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (_) {},
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4EB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.grid_view_rounded, color: AppColors.primary, size: 18),
                        onPressed: () {},
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.list_rounded, color: Colors.grey.shade400, size: 20),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 80), child: CircularProgressIndicator()))
              else if (_subCategories.isEmpty)
                // Empty State
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 80),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Transform.rotate(
                        angle: -0.2,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.local_offer_outlined,
                            size: 48,
                            color: Colors.grey.shade300,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No sub-categories found',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try adjusting your search or filter criteria',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              else
                _buildSubCategoryList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubCategoryList() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                dataRowHeight: 70,
                columnSpacing: 24,
                columns: [
                  DataColumn(label: Text('NAME', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('PARENT CATEGORY', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('DESCRIPTION', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('STATUS', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('ACTIONS', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12))),
                ],
                rows: _subCategories.map((sub) {
                  final parentName = sub['category']?['name'] ?? 'N/A';
                  final bool isSystem = sub['user'] == "000000000000000000000000";
                  
                  return DataRow(cells: [
                    DataCell(Text(sub['name'] ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.w500))),
                    DataCell(Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                      child: Text(parentName, style: GoogleFonts.inter(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.w600)),
                    )),
                    DataCell(SizedBox(
                      width: 250,
                      child: Text(sub['description'] ?? '', 
                        style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    )),
                    DataCell(Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                      child: Text(sub['status']?.toUpperCase() ?? 'ACTIVE', style: GoogleFonts.inter(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                    )),
                    DataCell(Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blue), 
                          onPressed: () => _showEditSubcategoryDialog(sub),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, size: 20, color: isSystem ? Colors.grey.shade300 : Colors.red), 
                          onPressed: isSystem ? null : () => _deleteSubCategory(sub['_id']),
                          tooltip: isSystem ? 'System subcategories cannot be deleted' : 'Delete',
                        ),
                      ],
                    )),
                  ]);
                }).toList(),
              ),
            ),
          ),
        );
      }
    );
  }


  void _showEditSubcategoryDialog(dynamic sub) {
    final TextEditingController nameController = TextEditingController(text: sub['name']);
    final TextEditingController descController = TextEditingController(text: sub['description']);
    String? selectedCategoryId = sub['category']?['_id'] ?? sub['category'];
    bool isActive = sub['status'] == 'active';
    bool isSubmitting = false;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.3),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              
              Future<void> submit() async {
                if (nameController.text.trim().isEmpty || selectedCategoryId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
                  return;
                }

                setDialogState(() => isSubmitting = true);
                try {
                  await ApiService().dio.put('/vendor/subcategory/${sub['_id']}', data: {
                    'name': nameController.text.trim(),
                    'description': descController.text.trim(),
                    'category': selectedCategoryId,
                    'status': isActive ? 'active' : 'inactive',
                  });
                  _fetchData();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subcategory updated')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
                } finally {
                  setDialogState(() => isSubmitting = false);
                }
              }

              return Dialog(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Container(
                  width: 450,
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Sub Category',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      _buildLabel('Name *'),
                      const SizedBox(height: 8),
                      _buildTextField('Enter sub category name', controller: nameController),
                      const SizedBox(height: 20),
                      
                      _buildLabel('Parent Category *'),
                      const SizedBox(height: 8),
                      _buildDropdownField(
                        'Select a parent category', 
                        value: selectedCategoryId,
                        items: _categories.map((c) => DropdownMenuItem(value: c['_id'].toString(), child: Text(c['name']))).toList(),
                        onChanged: (val) => setDialogState(() => selectedCategoryId = val),
                      ),
                      const SizedBox(height: 20),
                      
                      _buildLabel('Description'),
                      const SizedBox(height: 8),
                      _buildTextField('Enter sub category description', maxLines: 4, controller: descController),
                      const SizedBox(height: 20),
                      
                      Row(
                        children: [
                          Checkbox(
                            value: isActive,
                            onChanged: (val) => setDialogState(() => isActive = val ?? false),
                            activeColor: AppColors.primary,
                          ),
                          Text('Active', style: GoogleFonts.inter(fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textPrimary)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isSubmitting ? null : submit,
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                              child: isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Update', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showAddSubcategoryDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descController = TextEditingController();
    String? selectedCategoryId;
    bool isActive = true;
    bool isSubmitting = false;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.3),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              
              Future<void> submit() async {
                if (nameController.text.trim().isEmpty || selectedCategoryId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
                  return;
                }

                setDialogState(() => isSubmitting = true);
                try {
                  await ApiService().dio.post('/vendor/subcategory', data: {
                    'name': nameController.text.trim(),
                    'description': descController.text.trim(),
                    'category': selectedCategoryId,
                    'status': isActive ? 'active' : 'inactive',
                  });
                  _fetchData();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subcategory created')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                } finally {
                  setDialogState(() => isSubmitting = false);
                }
              }

              return Dialog(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Container(
                  width: 450,
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add New Sub Category',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      _buildLabel('Name *'),
                      const SizedBox(height: 8),
                      _buildTextField('Enter sub category name', controller: nameController),
                      const SizedBox(height: 20),
                      
                      _buildLabel('Parent Category *'),
                      const SizedBox(height: 8),
                      _buildDropdownField(
                        'Select a parent category', 
                        value: selectedCategoryId,
                        items: _categories.map((c) => DropdownMenuItem(value: c['_id'].toString(), child: Text(c['name']))).toList(),
                        onChanged: (val) => setDialogState(() => selectedCategoryId = val),
                      ),
                      const SizedBox(height: 20),
                      
                      _buildLabel('Description'),
                      const SizedBox(height: 8),
                      _buildTextField('Enter sub category description', maxLines: 4, controller: descController),
                      const SizedBox(height: 20),
                      
                      Row(
                        children: [
                          Checkbox(
                            value: isActive,
                            onChanged: (val) => setDialogState(() => isActive = val ?? false),
                            activeColor: AppColors.primary,
                          ),
                          Text('Active', style: GoogleFonts.inter(fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textPrimary)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isSubmitting ? null : submit,
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                              child: isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Create', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.grey.shade700,
      ),
    );
  }

  Widget _buildTextField(String hint, {int maxLines = 1, TextEditingController? controller}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDropdownField(String hint, {String? value, List<DropdownMenuItem<String>>? items, Function(String?)? onChanged}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          hint: Text(hint, style: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14)),
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          items: items ?? [],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
