import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:ojas_admin/features/layout/presentation/widgets/admin_layout.dart';
import 'package:ojas_admin/features/categories/data/services/category_service.dart';
import 'package:ojas_admin/features/categories/data/models/category_model.dart';
import 'package:ojas_admin/core/services/service_locator.dart';
import 'package:ojas_admin/core/services/api_service.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> with SingleTickerProviderStateMixin {
  final CategoryService _categoryService = sl<CategoryService>();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  
  List<CategoryModel> _categories = [];
  List<CategoryModel> _filteredCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _fetchCategories();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _fetchCategories();
  }

  void _onSearchChanged() {
    setState(() {
      _filteredCategories = _categories
          .where((cat) => cat.name.toLowerCase().contains(_searchController.text.toLowerCase()))
          .toList();
    });
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoading = true);
    try {
      final String type = _tabController.index == 0 ? 'global' : 'request';
      final data = await _categoryService.getCategories(type: type);
      setState(() {
        _categories = data.map((e) => CategoryModel.fromJson(e)).toList();
        _filteredCategories = _categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleRequest(String id, String status) async {
    try {
      await _categoryService.updateCategoryStatus(id, status);
      _fetchCategories();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Category request $status successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteCategory(String id) async {
    try {
      await _categoryService.deleteCategory(id);
      _fetchCategories();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _moveCategory(int index, int delta) async {
    final newIndex = index + delta;
    if (newIndex < 0 || newIndex >= _filteredCategories.length) return;
    final item = _filteredCategories[index];
    final otherItem = _filteredCategories[newIndex];

    final updatedCategories = [
      {'id': item.id, 'sequence': otherItem.sequence},
      {'id': otherItem.id, 'sequence': item.sequence == otherItem.sequence ? (delta > 0 ? otherItem.sequence - 1 : otherItem.sequence + 1) : item.sequence},
    ];

    try {
      await _categoryService.reorderCategories(updatedCategories);
      _fetchCategories();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reorder: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _toggleBestSelling(CategoryModel cat) async {
    try {
      await _categoryService.updateCategory(cat.id, {
        'name': cat.name,
        'isBestSelling': !cat.isBestSelling,
      });
      _fetchCategories();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAddEditModal({CategoryModel? category}) {
    showDialog(
      context: context,
      builder: (context) => CategoryFormModal(
        category: category,
        onSuccess: () {
          Navigator.pop(context);
          _fetchCategories();
        },
      ),
    );
  }

  void _showManageTrendingModal() {
    showDialog(
      context: context,
      builder: (context) => TrendingCategoriesModal(
        categories: _categories,
        onSuccess: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Trending categories updated! Storefront updated in real-time.'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      currentRoute: '/categories',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            color: Colors.white,
            child: Row(
              children: [
                Text('Master Admin', style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13)),
                const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                Text('Admin Categories', style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Row with Add Button & Trending Tabs Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Categories Management',
                            style: GoogleFonts.outfit(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage product categories and vendor requests',
                            style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 14),
                          ),
                        ],
                      ),
                      if (_tabController.index == 0)
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _showManageTrendingModal(),
                              icon: const Icon(Icons.tune, size: 18),
                              label: const Text('Manage Trending Tabs'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF6B21A8),
                                side: const BorderSide(color: Color(0xFF6B21A8), width: 1.5),
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () => _showAddEditModal(),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Global Category'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6B21A8),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Tabs
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        TabBar(
                          controller: _tabController,
                          labelColor: const Color(0xFF6B21A8),
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: const Color(0xFF6B21A8),
                          indicatorWeight: 3,
                          tabs: const [
                            Tab(text: 'Global Categories'),
                            Tab(text: 'Vendor Requests'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Search Bar Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
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
                                hintText: 'Search categories...',
                                hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Main Content
                  _isLoading
                      ? const Center(child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(),
                        ))
                      : _filteredCategories.isEmpty
                          ? _buildEmptyState()
                          : _tabController.index == 0
                              ? _buildCategoryTable()
                              : _buildRequestTable(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_offer_outlined, color: Colors.grey.shade300, size: 48),
            const SizedBox(height: 16),
            Text(
              'No categories found',
              style: GoogleFonts.inter(
                color: Colors.grey.shade500,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchCategories,
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('NAME', style: _tableHeaderStyle())),
                const SizedBox(width: 110, child: Text('SEQUENCE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey))),
                const SizedBox(width: 120, child: Text('BEST-SELLING', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey))),
                Expanded(flex: 3, child: Text('DESCRIPTION', style: _tableHeaderStyle())),
                Expanded(flex: 2, child: Text('PARENT', style: _tableHeaderStyle())),
                const SizedBox(width: 100, child: Text('ACTIONS', style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey,
                ))),
              ],
            ),
          ),
          // Table Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredCategories.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
            itemBuilder: (context, index) {
              final cat = _filteredCategories[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: (cat.image != null && cat.image!.isNotEmpty)
                                ? Image.network(
                                    cat.image!,
                                    width: 32,
                                    height: 32,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 32,
                                      height: 32,
                                      color: Colors.purple.shade50,
                                      child: const Icon(Icons.category, size: 16, color: Color(0xFF6B21A8)),
                                    ),
                                  )
                                : Container(
                                    width: 32,
                                    height: 32,
                                    color: Colors.purple.shade50,
                                    child: const Icon(Icons.category, size: 16, color: Color(0xFF6B21A8)),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              cat.name, 
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Sequence Reorder Column
                    SizedBox(
                      width: 110,
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_upward, size: 16, color: Color(0xFF475569)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                            onPressed: index > 0 ? () => _moveCategory(index, -1) : null,
                            tooltip: 'Move Up',
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.purple.shade200),
                            ),
                            child: Text(
                              '${cat.sequence}',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF6B21A8)),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_downward, size: 16, color: Color(0xFF475569)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                            onPressed: index < _filteredCategories.length - 1 ? () => _moveCategory(index, 1) : null,
                            tooltip: 'Move Down',
                          ),
                        ],
                      ),
                    ),
                    // Best Selling Toggle
                    SizedBox(
                      width: 120,
                      child: InkWell(
                        onTap: () => _toggleBestSelling(cat),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: cat.isBestSelling ? Colors.amber.shade50 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: cat.isBestSelling ? Colors.amber.shade400 : Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                cat.isBestSelling ? Icons.star : Icons.star_border,
                                size: 14,
                                color: cat.isBestSelling ? Colors.amber.shade800 : Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                cat.isBestSelling ? 'Top Star' : 'Normal',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: cat.isBestSelling ? Colors.amber.shade900 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(cat.description ?? '-', style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13)),
                    ),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          cat.parent ?? 'Main Category',
                          style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blue),
                            onPressed: () => _showAddEditModal(category: cat),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                            onPressed: () => _showDeleteDialog(cat),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRequestTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text('NAME', style: _tableHeaderStyle())),
                Expanded(flex: 2, child: Text('VENDOR', style: _tableHeaderStyle())),
                Expanded(flex: 3, child: Text('DESCRIPTION', style: _tableHeaderStyle())),
                const SizedBox(width: 150, child: Text('ACTIONS', style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey,
                ))),
              ],
            ),
          ),
          // Table Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredCategories.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
            itemBuilder: (context, index) {
              final cat = _filteredCategories[index];
              final vendorName = cat.user?['name'] ?? 'Unknown Vendor';
              final vendorEmail = cat.user?['email'] ?? '-';
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cat.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('PENDING', style: GoogleFonts.inter(fontSize: 10, color: Colors.amber.shade800, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(vendorName, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1E293B))),
                          Text(vendorEmail, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(cat.description ?? '-', style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13)),
                    ),
                    SizedBox(
                      width: 150,
                      child: Row(
                        children: [
                          ElevatedButton(
                            onPressed: () => _handleRequest(cat.id, 'approved'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            child: const Text('Approve', style: TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () => _handleRequest(cat.id, 'rejected'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            child: const Text('Reject', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  TextStyle _tableHeaderStyle() {
    return GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: Colors.grey.shade600,
      letterSpacing: 0.5,
    );
  }

  void _showDeleteDialog(CategoryModel cat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${cat.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCategory(cat.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class CategoryFormModal extends StatefulWidget {
  final CategoryModel? category;
  final VoidCallback onSuccess;

  const CategoryFormModal({super.key, this.category, required this.onSuccess});

  @override
  State<CategoryFormModal> createState() => _CategoryFormModalState();
}

class _CategoryFormModalState extends State<CategoryFormModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _sequenceController;
  bool _isBestSelling = false;
  String _selectedParent = 'No parent (Main Category)';
  bool _isSubmitting = false;
  List<CategoryModel> _availableCategories = [];
  bool _isLoadingCategories = true;
  String? _imageUrl;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name);
    _descriptionController = TextEditingController(text: widget.category?.description);
    _sequenceController = TextEditingController(text: (widget.category?.sequence ?? 0).toString());
    _isBestSelling = widget.category?.isBestSelling ?? false;
    _imageUrl = widget.category?.image;
    if (widget.category?.parent != null) {
      _selectedParent = widget.category!.parent!;
    }
    _fetchAvailableCategories();
  }

  Future<void> _fetchAvailableCategories() async {
    try {
      final data = await sl<CategoryService>().getCategories(type: 'global');
      if (mounted) {
        setState(() {
          _availableCategories = data.map((e) => CategoryModel.fromJson(e)).toList();
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCategories = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _sequenceController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image == null) return;

      setState(() => _isUploadingImage = true);

      final bytes = await image.readAsBytes();
      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(bytes, filename: image.name),
      });

      final response = await ApiService().dio.post(
        '/upload/image?folder=categories',
        data: formData,
      );

      if (response.statusCode == 200 && response.data['url'] != null) {
        setState(() {
          _imageUrl = response.data['url'];
          _isUploadingImage = false;
        });
      } else {
        throw Exception('Failed to upload image');
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final parentValue = _selectedParent == 'No parent (Main Category)'
          ? null
          : _selectedParent;

      final data = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'parent': parentValue,
        'sequence': int.tryParse(_sequenceController.text.trim()) ?? 0,
        'isBestSelling': _isBestSelling,
        'image': _imageUrl ?? '',
      };

      if (widget.category == null) {
        await sl<CategoryService>().createCategory(data);
      } else {
        await sl<CategoryService>().updateCategory(widget.category!.id, data);
      }
      widget.onSuccess();
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 540,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.category == null ? 'Add New Category' : 'Edit Category',
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Name *', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: _inputDecoration('Enter category name'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 20),
                Text('Description', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: _inputDecoration('Describe this category...'),
                ),
                const SizedBox(height: 20),

                // Category Image Field
                Text('Category Image', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                if (_isUploadingImage)
                  Container(
                    height: 110,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(height: 8),
                          Text('Uploading to ImageKit...', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  )
                else if (_imageUrl != null && _imageUrl!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _imageUrl!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Image Uploaded',
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.green.shade700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Displays in "Shop by Category" on storefront and category navigation.',
                                style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: _pickAndUploadImage,
                                    icon: const Icon(Icons.change_circle_outlined, size: 14),
                                    label: const Text('Change', style: TextStyle(fontSize: 12)),
                                    style: OutlinedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    onPressed: () => setState(() => _imageUrl = null),
                                    icon: const Icon(Icons.delete_outline, size: 14, color: Colors.red),
                                    label: const Text('Remove', style: TextStyle(fontSize: 12, color: Colors.red)),
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  InkWell(
                    onTap: _pickAndUploadImage,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload_outlined, size: 28, color: const Color(0xFF6B21A8).withValues(alpha: 0.8)),
                            const SizedBox(height: 6),
                            Text(
                              'Click to upload category image',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF6B21A8)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'PNG, JPG, WEBP (Square ratio recommended)',
                              style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),

                Text('Parent Category', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                _isLoadingCategories 
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedParent,
                          dropdownColor: Colors.white,
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<String>(
                              value: 'No parent (Main Category)',
                              child: Text('No parent (Main Category)'),
                            ),
                            ..._availableCategories.map((cat) {
                              return DropdownMenuItem<String>(
                                value: cat.name,
                                child: Text(cat.name),
                              );
                            }),
                          ],
                          onChanged: (v) => setState(() => _selectedParent = v!),
                        ),
                      ),
                    ),
                const SizedBox(height: 20),
                Text('Display Sequence / Order', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _sequenceController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('Enter sequence number (e.g. 1, 2, 3...)'),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50.withValues(alpha: 0.5),
                    border: Border.all(color: Colors.amber.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SwitchListTile(
                    title: Text(
                      'Mark as Best-Selling Category',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                    ),
                    subtitle: Text(
                      'Pin to the top of homepage and showcase prominently in best-selling sections',
                      style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    value: _isBestSelling,
                    activeTrackColor: Colors.amber.shade700,
                    onChanged: (val) => setState(() => _isBestSelling = val),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B21A8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(widget.category == null ? 'Create Category' : 'Update Category'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}

class TrendingCategoriesModal extends StatefulWidget {
  final List<CategoryModel> categories;
  final VoidCallback onSuccess;

  const TrendingCategoriesModal({
    super.key,
    required this.categories,
    required this.onSuccess,
  });

  @override
  State<TrendingCategoriesModal> createState() => _TrendingCategoriesModalState();
}

class _TrendingCategoriesModalState extends State<TrendingCategoriesModal> {
  bool _isLoading = true;
  bool _isSaving = false;
  final List<String> _selectedCategories = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentSettings() async {
    try {
      final response = await ApiService().dio.get('/admin/settings');
      if (response.statusCode == 200 && response.data['data'] != null) {
        final trendingStr = response.data['data']['trendingCategories'] as String? ?? '';
        final parsed = trendingStr
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty && e.toLowerCase() != 'all')
            .toList();
        setState(() {
          _selectedCategories.clear();
          _selectedCategories.addAll(parsed);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      final trendingString = _selectedCategories.join(', ');
      final response = await ApiService().dio.put(
        '/admin/settings',
        data: {'trendingCategories': trendingString},
      );
      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pop(context);
          widget.onSuccess();
        }
      } else {
        throw Exception('Failed to save settings: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allCategoryNames = widget.categories
        .map((c) => c.name.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();

    for (final sel in _selectedCategories) {
      if (!allCategoryNames.contains(sel)) {
        allCategoryNames.add(sel);
      }
    }

    final filteredNames = allCategoryNames
        .where((cat) => cat.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 680,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(28),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6B21A8).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.tune, color: Color(0xFF6B21A8), size: 24),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Manage Trending Items Tabs',
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Select the category tabs shown in the storefront Trending Items section',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Storefront Live Preview Bar
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.visibility_outlined, size: 14, color: Color(0xFF6B21A8)),
                            const SizedBox(width: 6),
                            Text(
                              'STOREFRONT PREVIEW (${_selectedCategories.length} tabs selected):',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF6B21A8),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEC4899),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'All',
                                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                              ..._selectedCategories.map((c) => Padding(
                                    padding: const EdgeInsets.only(left: 10),
                                    child: Chip(
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                                      label: Text(c, style: const TextStyle(fontSize: 12)),
                                      onDeleted: () {
                                        setState(() {
                                          _selectedCategories.remove(c);
                                        });
                                      },
                                      deleteIconColor: Colors.red.shade400,
                                      backgroundColor: Colors.white,
                                      side: BorderSide(color: Colors.grey.shade300),
                                    ),
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Search & Quick actions
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val),
                          decoration: InputDecoration(
                            hintText: 'Search categories...',
                            prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            for (final c in allCategoryNames) {
                              if (!_selectedCategories.contains(c)) {
                                _selectedCategories.add(c);
                              }
                            }
                          });
                        },
                        icon: const Icon(Icons.select_all, size: 16),
                        label: const Text('Select All'),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedCategories.clear();
                          });
                        },
                        icon: const Icon(Icons.clear_all, size: 16),
                        label: const Text('Clear All'),
                        style: TextButton.styleFrom(foregroundColor: Colors.red.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Category Selection List
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: filteredNames.isEmpty
                          ? const Center(child: Text('No categories match your search'))
                          : ListView.separated(
                              itemCount: filteredNames.length,
                              separatorBuilder: (_, index) => Divider(height: 1, color: Colors.grey.shade100),
                              itemBuilder: (context, index) {
                                final cat = filteredNames[index];
                                final isSelected = _selectedCategories.contains(cat);
                                return CheckboxListTile(
                                  value: isSelected,
                                  dense: true,
                                  activeColor: const Color(0xFF6B21A8),
                                  title: Text(
                                    cat,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                      color: isSelected ? const Color(0xFF0F172A) : Colors.grey.shade700,
                                    ),
                                  ),
                                  onChanged: (bool? val) {
                                    setState(() {
                                      if (val == true) {
                                        if (!_selectedCategories.contains(cat)) {
                                          _selectedCategories.add(cat);
                                        }
                                      } else {
                                        _selectedCategories.remove(cat);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _isSaving ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveSettings,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check, size: 18),
                        label: Text(_isSaving ? 'Saving...' : 'Save & Update Storefront'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B21A8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

