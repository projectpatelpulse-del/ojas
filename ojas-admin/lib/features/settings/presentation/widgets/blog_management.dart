import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_admin/core/services/api_service.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class BlogManagement extends StatefulWidget {
  const BlogManagement({super.key});

  @override
  State<BlogManagement> createState() => _BlogManagementState();
}

class _BlogManagementState extends State<BlogManagement> {
  List<dynamic> _blogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBlogs();
  }

  Future<void> _fetchBlogs() async {
    try {
      setState(() => _isLoading = true);
      final response = await ApiService().dio.get('/admin/blogs');
      if (response.data['success']) {
        setState(() {
          _blogs = response.data['data'];
        });
      }
    } catch (e) {
      debugPrint('Error fetching blogs: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteBlog(String id) async {
    try {
      final response = await ApiService().dio.delete('/admin/blogs/$id');
      if (response.data['success']) {
        _fetchBlogs();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Blog deleted successfully')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error deleting blog: $e');
    }
  }

  void _showBlogForm({Map<String, dynamic>? blog}) {
    showDialog(
      context: context,
      builder: (context) => BlogFormDialog(
        blog: blog,
        onSuccess: () {
          Navigator.pop(context);
          _fetchBlogs();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Blog Management',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create and manage blog articles for your website.',
                  style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 14),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () => _showBlogForm(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create New Blog'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (_blogs.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Column(
                children: [
                  Icon(Icons.article_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No blogs found. Start by creating your first article!',
                    style: GoogleFonts.inter(color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              mainAxisExtent: 320,
            ),
            itemCount: _blogs.length,
            itemBuilder: (context, index) {
              final blog = _blogs[index];
              return _buildBlogCard(blog);
            },
          ),
      ],
    );
  }

  Widget _buildBlogCard(Map<String, dynamic> blog) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              blog['image'] ?? '',
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 160,
                color: Colors.grey.shade100,
                child: const Icon(Icons.image_outlined, color: Colors.grey),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF01B6B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        blog['category'] ?? 'General',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFF01B6B),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      blog['readingTime'] ?? '5 min read',
                      style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  blog['title'] ?? 'Untitled',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.1),
                      child: const Icon(Icons.person, size: 14, color: Color(0xFF8B5CF6)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      blog['authorName'] ?? 'Admin',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                      onPressed: () => _showBlogForm(blog: blog),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      onPressed: () => _deleteBlog(blog['_id']),
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
    );
  }
}

class BlogFormDialog extends StatefulWidget {
  final Map<String, dynamic>? blog;
  final VoidCallback onSuccess;

  const BlogFormDialog({super.key, this.blog, required this.onSuccess});

  @override
  State<BlogFormDialog> createState() => _BlogFormDialogState();
}

class _BlogFormDialogState extends State<BlogFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _subtitleController;
  late TextEditingController _contentController;
  late TextEditingController _categoryController;
  late TextEditingController _authorNameController;
  late TextEditingController _readingTimeController;
  
  bool _isFeatured = false;
  bool _isSaving = false;
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.blog?['title'] ?? '');
    _subtitleController = TextEditingController(text: widget.blog?['subtitle'] ?? '');
    _contentController = TextEditingController(text: widget.blog?['content'] ?? '');
    _categoryController = TextEditingController(text: widget.blog?['category'] ?? '');
    _authorNameController = TextEditingController(text: widget.blog?['authorName'] ?? 'Admin');
    _readingTimeController = TextEditingController(text: widget.blog?['readingTime'] ?? '5 min read');
    _isFeatured = widget.blog?['isFeatured'] ?? false;
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _imageFile = image;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final Map<String, dynamic> data = {
        'title': _titleController.text,
        'subtitle': _subtitleController.text,
        'content': _contentController.text,
        'category': _categoryController.text,
        'authorName': _authorNameController.text,
        'readingTime': _readingTimeController.text,
        'isFeatured': _isFeatured,
      };

      final formData = FormData.fromMap(data);

      if (_imageFile != null) {
        final bytes = await _imageFile!.readAsBytes();
        formData.files.add(MapEntry(
          'image',
          MultipartFile.fromBytes(
            bytes,
            filename: _imageFile!.name,
          ),
        ));
      } else if (widget.blog?['image'] != null) {
        formData.fields.add(MapEntry('imageUrl', widget.blog!['image']));
      }

      Response response;
      if (widget.blog != null) {
        response = await ApiService().dio.put('/admin/blogs/${widget.blog!['_id']}', data: formData);
      } else {
        response = await ApiService().dio.post('/admin/blogs', data: formData);
      }

      if (response.data['success']) {
        widget.onSuccess();
      }
    } catch (e) {
      debugPrint('Error saving blog: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.blog != null ? 'Edit Blog' : 'Create New Blog', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildImageUploadSection(),
                const SizedBox(height: 20),
                _buildTextField('Title', _titleController, required: true),
                const SizedBox(height: 16),
                _buildTextField('Subtitle / Summary', _subtitleController),
                const SizedBox(height: 16),
                _buildTextField('Category', _categoryController, required: true),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTextField('Author Name', _authorNameController)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField('Reading Time', _readingTimeController)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField('Content', _contentController, maxLines: 10, required: true),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(value: _isFeatured, onChanged: (v) => setState(() => _isFeatured = v!)),
                    const Text('Featured Article'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), foregroundColor: Colors.white),
          child: _isSaving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Blog Banner Image', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickImage,
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
            ),
            child: _imageFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: kIsWeb
                        ? Image.network(_imageFile!.path, fit: BoxFit.cover)
                        : Image.network(_imageFile!.path, fit: BoxFit.cover), // Simplified for brevity
                  )
                : widget.blog?['image'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(widget.blog!['image'], fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text('Click to upload banner image', style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13)),
                          Text('Recommended: 1200x600px', style: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 11)),
                        ],
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool required = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: required ? (v) => v!.isEmpty ? 'Field required' : null : null,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}
