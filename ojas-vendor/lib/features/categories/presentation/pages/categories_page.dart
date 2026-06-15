import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_vendor/core/constants/app_colors.dart';
import 'package:ojas_vendor/core/widgets/sidebar_layout.dart';
import 'package:ojas_vendor/core/widgets/vendor_topbar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:ojas_vendor/core/services/api_service.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isGridView = true;
  bool _isLoading = true;
  List<dynamic> _categories = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await ApiService().dio.get('/vendor/category');
      if (response.statusCode == 200) {
        setState(() {
          _categories = response.data['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load categories: $e')));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteCategory(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Category', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete this category? This action cannot be undone.', style: GoogleFonts.inter()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey))),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete', style: GoogleFonts.inter(fontWeight: FontWeight.bold))
          ),
        ],
      )
    );

    if (confirmed == true) {
      try {
        await ApiService().dio.delete('/vendor/category/$id');
        _fetchCategories();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category deleted successfully')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
        }
      }
    }
  }

  void _showEditCategoryDialog(BuildContext context, dynamic category) {
    final TextEditingController nameController = TextEditingController(text: category['name']);
    final TextEditingController descController = TextEditingController(text: category['description']);
    String parentCategory = category['parent'] ?? 'No parent (Main Category)';
    XFile? selectedImage;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickImage() async {
              final ImagePicker picker = ImagePicker();
              final XFile? image = await picker.pickImage(source: ImageSource.gallery);
              if (image != null) setDialogState(() => selectedImage = image);
            }

            Future<void> updateCategory() async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter category name')));
                return;
              }
              setDialogState(() => isSubmitting = true);
              try {
                FormData formData = FormData.fromMap({
                  'name': nameController.text.trim(),
                  'description': descController.text.trim(),
                  'parent': parentCategory,
                });
                if (selectedImage != null) {
                  final bytes = await selectedImage!.readAsBytes();
                  formData.files.add(MapEntry('image', MultipartFile.fromBytes(bytes, filename: selectedImage!.name)));
                }
                await ApiService().dio.put('/vendor/category/${category['_id']}', data: formData);
                _fetchCategories();
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category updated successfully')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
              } finally {
                setDialogState(() => isSubmitting = false);
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                width: 700,
                padding: const EdgeInsets.all(0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Edit Category', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                          IconButton(onPressed: () => Navigator.of(dialogContext).pop(), icon: const Icon(Icons.close)),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                _buildDialogInputField('Name *', 'Enter name', controller: nameController),
                                const SizedBox(height: 16),
                                _buildDialogInputField('Description', 'Describe...', controller: descController, maxLines: 5),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Category Image', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 8),
                                Container(
                                  height: 190,
                                  width: double.infinity,
                                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (selectedImage == null && category['image'] != null)
                                        ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.network(category['image'], height: 80, fit: BoxFit.cover)),
                                      if (selectedImage != null) const Icon(Icons.check_circle, size: 40, color: Colors.green),
                                      const SizedBox(height: 12),
                                      Text(selectedImage != null ? 'New Image Selected' : 'Change Image'),
                                      const SizedBox(height: 16),
                                      OutlinedButton(onPressed: pickImage, child: const Text('Choose Image')),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildDialogDropdownField('Parent Category', ['No parent (Main Category)', 'Electronics', 'Fashion'], value: parentCategory, onChanged: (v) => setDialogState(() => parentCategory = v!)),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel'))),
                          const SizedBox(width: 16),
                          Expanded(child: ElevatedButton(onPressed: isSubmitting ? null : updateCategory, child: isSubmitting ? const CircularProgressIndicator() : const Text('Update Category'))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SidebarLayout(
      activeRoute: '/categories',
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: const VendorTopBar(),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Categories',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage product categories. ${_categories.length} active ${_categories.length == 1 ? "category" : "categories"}.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showAddCategoryDialog(context);
                    },
                    icon: const Icon(Icons.add, size: 20),
                    label: Text(
                      'Add Category',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
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
                  _buildStatCard('${_categories.length}', 'Total Categories', Colors.blue),
                  const SizedBox(width: 24),
                  _buildStatCard('${_categories.length}', 'Active Categories', Colors.green),
                  const SizedBox(width: 24),
                  _buildStatCard(
                    _categories.where((c) => c['user'] == "000000000000000000000000").length.toString(), 
                    'System Categories', 
                    Colors.blue
                  ),
                  const SizedBox(width: 24),
                  _buildStatCard(
                    _categories.where((c) => c['user'] != "000000000000000000000000").length.toString(), 
                    'My Categories', 
                    Colors.purple
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Search and Layout Toggles
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search categories...',
                            hintStyle: GoogleFonts.inter(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.grey.shade400,
                              size: 20,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 11,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Grid Toggle
                    _buildLayoutToggleButton(
                      icon: Icons.grid_view_rounded,
                      isActive: _isGridView,
                      onTap: () => setState(() => _isGridView = true),
                    ),
                    const SizedBox(width: 8),
                    // List Toggle
                    _buildLayoutToggleButton(
                      icon: Icons.format_list_bulleted_rounded,
                      isActive: !_isGridView,
                      onTap: () => setState(() => _isGridView = false),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 80),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_categories.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 80),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade100),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.grid_view_rounded,
                            size: 48,
                            color: Colors.grey.shade300,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No categories found',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your search criteria or add a new category.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_isGridView)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return _buildCategoryCard(category);
                  },
                )
              else
                _buildCategoryList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayoutToggleButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFFF0E6) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isActive ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descController = TextEditingController();
    String parentCategory = 'No parent (Main Category)';
    XFile? selectedImage;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {

            Future<void> pickImage() async {
              final ImagePicker picker = ImagePicker();
              final XFile? image = await picker.pickImage(source: ImageSource.gallery);
              if (image != null) {
                setDialogState(() {
                  selectedImage = image;
                });
              }
            }

            Future<void> createCategory() async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter category name')));
                return;
              }

              setDialogState(() => isSubmitting = true);

              try {
                final apiService = ApiService();
                FormData formData = FormData.fromMap({
                  'name': nameController.text.trim(),
                  'description': descController.text.trim(),
                  'parent': parentCategory,
                });

                if (selectedImage != null) {
                  final bytes = await selectedImage!.readAsBytes();
                  formData.files.add(MapEntry(
                    'image',
                    MultipartFile.fromBytes(bytes, filename: selectedImage!.name),
                  ));
                }

                await apiService.dio.post('/vendor/category', data: formData);

                _fetchCategories(); // Refresh data on UI dynamically!
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category created successfully')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create category: $e')));
              } finally {
                setDialogState(() => isSubmitting = false);
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: Colors.white,
              child: Container(
                width: 700,
                padding: const EdgeInsets.all(0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Add New Category',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(Icons.close, color: Colors.grey),
                            splashRadius: 24,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    // Form Fields
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDialogInputField('Name *', 'Enter category name', controller: nameController),
                                const SizedBox(height: 16),
                                _buildDialogInputField('Description', 'Describe this category...', controller: descController, maxLines: 5),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          // Right Column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Category Image',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 190,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (selectedImage != null)
                                        Icon(Icons.check_circle, size: 40, color: Colors.green.shade400)
                                      else
                                        Icon(Icons.file_upload_outlined, size: 40, color: Colors.blueGrey.shade300),
                                      const SizedBox(height: 12),
                                      Text(
                                        selectedImage != null ? 'Image Selected' : 'Upload a category image',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        selectedImage != null ? selectedImage!.name : 'PNG, JPG, JPEG, WebP up to 5MB',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      OutlinedButton(
                                        onPressed: pickImage,
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(color: Colors.grey.shade300),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        ),
                                        child: Text(
                                          selectedImage != null ? 'Change Image' : 'Choose Image',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.textPrimary,
                                          ),
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
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildDialogDropdownField(
                        'Parent Category', 
                        ['No parent (Main Category)', 'Electronics', 'Fashion'],
                        value: parentCategory,
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => parentCategory = val);
                          }
                        }
                      ),
                    ),
                const SizedBox(height: 24),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                // Footer Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isSubmitting ? null : createCategory,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                          ),
                          child: isSubmitting
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(
                                  'Create Category',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
          },
        );
      },
    );
  }

  Widget _buildDialogInputField(String label, String hint, {int maxLines = 1, TextEditingController? controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildDialogDropdownField(String label, List<String> items, {String? value, Function(String?)? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.primary, width: 1.5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value ?? items.first,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, size: 20),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged ?? (_) {},
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildCategoryList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              color: const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: _listHeader('Category')),
                Expanded(flex: 3, child: _listHeader('Description')),
                Expanded(flex: 2, child: _listHeader('Level')),
                Expanded(flex: 1, child: _listHeader('Vendor')),
                Expanded(flex: 1, child: _listHeader('Status')),
                Expanded(flex: 1, child: _listHeader('Created')),
                Expanded(flex: 1, child: Center(child: _listHeader('Actions'))),
              ],
            ),
          ),
          // Table Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _categories.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final category = _categories[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: category['image'] != null && category['image'].toString().isNotEmpty
                              ? Image.network(category['image'], width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(width: 40, height: 40, color: Colors.grey.shade200, child: const Icon(Icons.image, size: 20)))
                              : Container(width: 40, height: 40, color: Colors.grey.shade200, child: const Icon(Icons.category, size: 20, color: Colors.grey)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            category['name'] ?? '-',
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )),
                    Expanded(flex: 3, child: Text(
                      category['description'] ?? '-',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    )),
                    Expanded(flex: 2, child: Text(
                      category['parent'] ?? 'Main Category',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    )),
                    Expanded(flex: 1, child: Text(
                      'Self', // Or category['vendor'] name if available
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
                    )),
                    Expanded(flex: 1, child: _buildStatusBadge(category['status'] ?? 'approved')),
                    Expanded(flex: 1, child: Text(
                      category['createdAt'] != null ? category['createdAt'].toString().substring(0, 10) : '-',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                    )),
                    Expanded(flex: 1, child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () => _showEditCategoryDialog(context, category),
                          icon: Icon(Icons.edit_outlined, size: 18, color: Colors.blue.shade400),
                          tooltip: 'Edit',
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: () => _deleteCategory(category['_id']),
                          icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400),
                          tooltip: 'Delete',
                        ),
                      ],
                    )),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _listHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
    );
  }

  Widget _buildCategoryCard(dynamic category) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: category['image'] != null && category['image'].toString().isNotEmpty
                      ? Image.network(
                          category['image'],
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey)),
                        )
                      : Container(
                          width: double.infinity,
                          color: Colors.grey.shade100,
                          child: const Icon(Icons.category, size: 40, color: Colors.grey),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category['name'] ?? 'Unnamed Category',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category['parent'] ?? 'No parent',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    _buildStatusBadge(category['status'] ?? 'approved'),
                  ],
                ),
              ),
            ],
          ),
          // Action Buttons Overlay
          Positioned(
            top: 12,
            right: 12,
            child: Row(
              children: [
                _buildCardAction(Icons.edit, Colors.blue, () => _showEditCategoryDialog(context, category)),
                const SizedBox(width: 8),
                _buildCardAction(Icons.delete, Colors.red, () => _deleteCategory(category['_id'])),
              ],
            ),
          ),
        ],
      ),
    );
  }

    Widget _buildStatusBadge(String status) {
      Color bgColor;
      Color textColor;
      String label = status.toUpperCase();

      switch (status) {
        case 'pending':
          bgColor = Colors.amber.shade50;
          textColor = Colors.amber.shade800;
          break;
        case 'rejected':
          bgColor = Colors.red.shade50;
          textColor = Colors.red.shade800;
          break;
        default:
          bgColor = Colors.green.shade50;
          textColor = Colors.green.shade800;
          label = 'APPROVED';
      }

      return UnconstrainedBox(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
          child: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: textColor)),
        ),
      );
    }

    Widget _buildCardAction(IconData icon, Color color, VoidCallback onTap) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: IconButton(
          icon: Icon(icon, size: 16, color: color),
          onPressed: onTap,
          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          padding: EdgeInsets.zero,
        ),
      );
    }
}
