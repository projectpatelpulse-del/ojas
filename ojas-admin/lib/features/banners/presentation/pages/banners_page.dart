import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_admin/core/services/service_locator.dart';
import 'package:ojas_admin/features/banners/data/models/banner_model.dart';
import 'package:ojas_admin/features/banners/data/services/banner_service.dart';
import 'package:ojas_admin/features/layout/presentation/widgets/admin_layout.dart';

class BannersPage extends StatefulWidget {
  const BannersPage({super.key});

  @override
  State<BannersPage> createState() => _BannersPageState();
}

class _BannersPageState extends State<BannersPage> {
  BannerService get _bannerService => sl<BannerService>();
  List<BannerModel> _banners = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBanners();
  }

  Future<void> _fetchBanners() async {
    setState(() => _isLoading = true);
    try {
      final banners = await _bannerService.getBanners();
      setState(() {
        _banners = banners;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching banners: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load banners: $e')),
        );
      }
    }
  }

  void _showBannerDialog([BannerModel? banner]) {
    showDialog(
      context: context,
      builder: (context) => BannerFormDialog(
        banner: banner,
        existingBanners: _banners,
        onSave: () {
          _fetchBanners();
        },
      ),
    );
  }

  Future<void> _deleteBanner(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Banner'),
        content: const Text('Are you sure you want to delete this banner?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _bannerService.deleteBanner(id);
        _fetchBanners();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete banner: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      currentRoute: '/banners',
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
                Text('Hero Banners', style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hero Banners Management',
                            style: GoogleFonts.outfit(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Control the sliders and promotional banners on your home page.',
                            style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 14),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showBannerDialog(),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text('Add New Banner', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B21A8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_banners.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 80),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.image_outlined, color: Colors.grey.shade300, size: 64),
                          const SizedBox(height: 16),
                          Text(
                            'No banners found',
                            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start by adding your first hero banner.',
                            style: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 24,
                        mainAxisSpacing: 24,
                        childAspectRatio: 1.4,
                      ),
                      itemCount: _banners.length,
                      itemBuilder: (context, index) {
                        final banner = _banners[index];
                        return _buildBannerCard(banner);
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerCard(BannerModel banner) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    banner.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey.shade100,
                      child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getTypeColor(banner.type),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getTypeLabel(banner.type),
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (banner.tag.isNotEmpty)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          banner.tag,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    banner.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    banner.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () => _showBannerDialog(banner),
                        icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blue),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: () => _deleteBanner(banner.id),
                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'main':
      case 'main_slider':
        return Colors.blue;
      case 'side_top':
        return Colors.pink;
      case 'side_bottom':
        return Colors.teal;
      case 'offer':
        return Colors.orange;
      case 'trending':
        return Colors.purple;
      case 'promo':
        return Colors.indigo;
      case 'summer_sale':
        return Colors.redAccent;
      case 'become_vendor':
        return Colors.tealAccent.shade700;
      default:
        return Colors.grey;
    }
  }
}

String _getTypeLabel(String type) {
  switch (type) {
    case 'main_slider':
      return 'Hero Top Slider (Carousel)';
    case 'side_top':
      return 'Hero Right Top';
    case 'side_bottom':
      return 'Hero Right Bottom';
    case 'offer':
      return 'Bottom Offer Card';
    case 'trending':
      return 'Trending Section Banner';
    case 'promo':
      return 'Weekend Deals Slider';
    case 'summer_sale':
      return 'Summer Sale Banner';
    case 'become_vendor':
      return 'Become Vendor Banner';
    default:
      return type.replaceAll('_', ' ').toUpperCase();
  }
}

class BannerFormDialog extends StatefulWidget {
  final BannerModel? banner;
  final List<BannerModel> existingBanners;
  final VoidCallback onSave;

  const BannerFormDialog({super.key, this.banner, required this.existingBanners, required this.onSave});

  @override
  State<BannerFormDialog> createState() => _BannerFormDialogState();
}

class _BannerFormDialogState extends State<BannerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _subtitleController;
  late TextEditingController _linkController;
  late TextEditingController _tagController;
  String _selectedType = 'main_slider';
  bool _isActive = true;
  
  Uint8List? _selectedImageBytes;
  String? _selectedFileName;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.banner?.title);
    _subtitleController = TextEditingController(text: widget.banner?.subtitle);
    _linkController = TextEditingController(text: widget.banner?.link ?? '/');
    _tagController = TextEditingController(text: widget.banner?.tag);
    final String initialType = widget.banner?.type ?? 'main_slider';
    _selectedType = (initialType == 'main' || initialType == 'main_slider_1' || initialType == 'main_slider_2')
        ? 'main_slider'
        : initialType;
    _isActive = widget.banner?.isActive ?? true;
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedFileName = image.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  // Carousel types allow multiple images.
  final List<String> _carouselTypes = const ['main_slider', 'promo'];

  Future<void> _handleSave() async {
    final isNew = widget.banner == null;
    final isCarousel = _carouselTypes.contains(_selectedType);
    
    if (!isCarousel) {
      final typeExists = widget.existingBanners.any((b) => 
        b.type == _selectedType && 
        (isNew || b.id != widget.banner!.id)
      );
      if (typeExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('A banner of type "${_getTypeLabel(_selectedType)}" already exists. You must delete the existing one first.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final bannerService = sl<BannerService>();
      if (widget.banner == null) {
        await bannerService.createBanner(
          title: _titleController.text,
          subtitle: _subtitleController.text,
          link: _linkController.text,
          tag: _tagController.text,
          type: _selectedType,
          imageBytes: _selectedImageBytes,
          fileName: _selectedFileName,
        );
      } else {
        await bannerService.updateBanner(
          id: widget.banner!.id,
          title: _titleController.text,
          subtitle: _subtitleController.text,
          link: _linkController.text,
          tag: _tagController.text,
          type: _selectedType,
          isActive: _isActive,
          imageBytes: _selectedImageBytes,
          fileName: _selectedFileName,
        );
      }
      widget.onSave();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save banner: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.banner == null ? 'Add New Banner' : 'Edit Banner'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: InkWell(
                    onTap: _pickImage,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300, width: 2, style: BorderStyle.solid),
                      ),
                      child: _selectedImageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.memory(_selectedImageBytes!, fit: BoxFit.cover),
                            )
                          : (widget.banner != null && widget.banner!.imageUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    widget.banner!.imageUrl, 
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => _buildUploadPlaceholder(),
                                  ),
                                )
                              : _buildUploadPlaceholder()),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: const InputDecoration(labelText: 'Banner Type', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'main_slider',      child: Text('Hero Top Slider – Carousel ')),
                    DropdownMenuItem(value: 'promo',            child: Text('Weekend Deals Slider – Carousel')),
                    DropdownMenuItem(value: 'side_top', child: Text('Hero Section - Right Top Banner')),
                    DropdownMenuItem(value: 'side_bottom', child: Text('Hero Section - Right Bottom Banner')),
                    DropdownMenuItem(value: 'offer', child: Text('Bottom Offer Card (Next to Newsletter)')),
                    DropdownMenuItem(value: 'trending', child: Text('Trending Products Section Banner')),
                    DropdownMenuItem(value: 'summer_sale', child: Text('Summer Sale Banner (Middle of Homepage)')),
                    DropdownMenuItem(value: 'become_vendor', child: Text('Become Vendor Banner (Middle of Homepage)')),
                    DropdownMenuItem(value: 'gift_promo_strip', child: Text('Gift Promo Strip (Why Choose Ojas Banner)')),
                    // DropdownMenuItem(value: 'how_it_works', child: Text('How it Works Banner')),
                    DropdownMenuItem(value: 'b2b_partner', child: Text('B2B Partner Banner (Trusted Gifting Partner Banner)')),
                  ],
                  onChanged: (v) => setState(() => _selectedType = v!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _subtitleController,
                  decoration: const InputDecoration(labelText: 'Subtitle', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _tagController,
                        decoration: const InputDecoration(labelText: 'Tag (e.g. HOT DEAL)', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _linkController,
                        decoration: const InputDecoration(labelText: 'Action Link', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                if (widget.banner != null) ...[
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Is Active'),
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isSaving ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6B21A8),
            foregroundColor: Colors.white,
          ),
          child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save Banner'),
        ),
      ],
    );
  }

  Widget _buildUploadPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.cloud_upload_outlined, color: Colors.grey.shade600, size: 32),
        ),
        const SizedBox(height: 12),
        Text(
          'Click to upload image',
          style: GoogleFonts.inter(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Recommended: 1200x600 for main banners',
          style: GoogleFonts.inter(
            color: Colors.grey.shade400,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
