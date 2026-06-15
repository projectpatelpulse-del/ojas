import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_user/core/widgets/ojas_layout.dart';
import 'package:ojas_user/core/widgets/centered_content.dart';
import 'package:ojas_user/core/utils/responsive.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ojas_user/core/services/api_service.dart';
import 'package:ojas_user/core/services/socket_service.dart';

class BlogDetailPage extends StatefulWidget {
  final String blogId;
  final Map<String, dynamic>? initialData;

  const BlogDetailPage({
    super.key, 
    required this.blogId, 
    this.initialData,
  });

  @override
  State<BlogDetailPage> createState() => _BlogDetailPageState();
}

class _BlogDetailPageState extends State<BlogDetailPage> {
  Map<String, dynamic>? _blog;
  bool _isLoading = true;
  bool _isMarkingRead = false;
  late Function(dynamic) _blogUpdateListener;

  @override
  void initState() {
    super.initState();
    _blog = widget.initialData;
    _fetchBlogDetails();
    _setupSocketListener();
  }

  void _setupSocketListener() {
    _blogUpdateListener = (data) {
      if (data != null && data['data'] != null && data['data']['_id'] == widget.blogId) {
        setState(() {
          _blog = data['data'];
        });
      }
    };
    SocketService.instance.on('blog', _blogUpdateListener);
  }

  @override
  void dispose() {
    SocketService.instance.off('blog', _blogUpdateListener);
    super.dispose();
  }

  Future<void> _fetchBlogDetails() async {
    try {
      if (_blog == null) setState(() => _isLoading = true);
      final response = await http.get(Uri.parse('${ApiService.baseUrl}/home/blogs/${widget.blogId}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _blog = data['data'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching blog details: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead() async {
    try {
      setState(() => _isMarkingRead = true);
      final response = await http.post(Uri.parse('${ApiService.baseUrl}/home/blogs/${widget.blogId}/view'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _blog = data['data'];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Marked as read! View count updated.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error marking blog as read: $e');
    } finally {
      setState(() => _isMarkingRead = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);

    return OjasLayout(
      activeTitle: 'BLOG',
      child: Container(
        color: Colors.white,
        child: _isLoading && _blog == null
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFF01B6B)))
            : _blog == null
                ? const Center(child: Text('Blog not found'))
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hero Image Section
                        _buildHeroImage(isMobile),
                        
                        CenteredContent(
                          horizontalPadding: isMobile ? 16 : 40,
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: isMobile ? 30 : 60),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Category and Date
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF01B6B).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _blog!['category'] ?? 'General',
                                        style: GoogleFonts.inter(
                                          color: const Color(0xFFF01B6B),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      _blog!['readingTime'] ?? '5 min read',
                                      style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13),
                                    ),
                                    const Spacer(),
                                    // Mark as Read Button
                                    ElevatedButton.icon(
                                      onPressed: _isMarkingRead ? null : _markAsRead,
                                      icon: _isMarkingRead 
                                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                        : const Icon(Icons.check_circle_outline, size: 18),
                                      label: Text(_isMarkingRead ? 'Processing...' : 'Mark Read'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFF01B6B),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                
                                // Title
                                Text(
                                  _blog!['title'] ?? 'Untitled',
                                  style: GoogleFonts.outfit(
                                    fontSize: isMobile ? 32 : 48,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                // Subtitle
                                if (_blog!['subtitle'] != null && _blog!['subtitle'].isNotEmpty)
                                  Text(
                                    _blog!['subtitle'],
                                    style: GoogleFonts.inter(
                                      fontSize: isMobile ? 18 : 22,
                                      color: const Color(0xFF64748B),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                
                                const SizedBox(height: 40),
                                const Divider(),
                                const SizedBox(height: 40),
                                
                                // Author and Views
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundImage: _blog!['authorImage'] != null && _blog!['authorImage'] != ''
                                          ? NetworkImage(_blog!['authorImage'])
                                          : const NetworkImage('https://i.pravatar.cc/150?img=1'),
                                      radius: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _blog!['authorName'] ?? 'Admin',
                                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        Text(
                                          'Author',
                                          style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.remove_red_eye_outlined, size: 18, color: Color(0xFFF01B6B)),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${_blog!['views'] ?? 0} Views',
                                              style: GoogleFonts.inter(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: const Color(0xFF0F172A),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          'Total Reads',
                                          style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 60),
                                
                                // Content
                                Text(
                                  _blog!['content'] ?? '',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    color: const Color(0xFF334155),
                                    height: 1.8,
                                  ),
                                ),
                                
                                const SizedBox(height: 80),
                                
                                // Back Button
                                Center(
                                  child: OutlinedButton.icon(
                                    onPressed: () => Navigator.pop(context),
                                    icon: const Icon(Icons.arrow_back),
                                    label: const Text('Back to Blog'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF0F172A),
                                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildHeroImage(bool isMobile) {
    return Container(
      height: isMobile ? 300 : 500,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
      ),
      child: Image.network(
        _blog!['image'] ?? '',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
        ),
      ),
    );
  }
}
