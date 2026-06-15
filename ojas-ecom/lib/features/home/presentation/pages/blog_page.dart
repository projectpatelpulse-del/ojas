import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_user/core/widgets/ojas_layout.dart';
import 'package:ojas_user/core/widgets/centered_content.dart';
import 'package:ojas_user/core/utils/responsive.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ojas_user/core/services/api_service.dart';
import 'package:ojas_user/core/services/socket_service.dart';
import 'package:ojas_user/features/home/presentation/pages/blog_detail_page.dart';

class BlogPage extends StatefulWidget {
  const BlogPage({super.key});

  @override
  State<BlogPage> createState() => _BlogPageState();
}

class _BlogPageState extends State<BlogPage> {
  String _selectedCategory = 'All';
  List<dynamic> _blogs = [];
  List<String> _categories = ['All'];
  bool _isLoading = true;
  
  late Function(dynamic) _adminUpdateListener;

  @override
  void initState() {
    super.initState();
    _fetchBlogs();
    _setupSocketListener();
  }

  void _setupSocketListener() {
    _adminUpdateListener = (data) {
      debugPrint('Blog updated via socket, refreshing list...');
      _fetchBlogs();
    };
    SocketService.instance.on('blog', _adminUpdateListener);
  }

  @override
  void dispose() {
    SocketService.instance.off('blog', _adminUpdateListener);
    super.dispose();
  }

  Future<void> _fetchBlogs() async {
    try {
      setState(() => _isLoading = true);
      final response = await http.get(Uri.parse('${ApiService.baseUrl}/home/blogs'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final blogs = data['data'] as List;
          final categoriesSet = {'All'};
          for (var blog in blogs) {
            if (blog['category'] != null && blog['category'].toString().isNotEmpty) {
              categoriesSet.add(blog['category']);
            }
          }
          
          setState(() {
            _blogs = blogs;
            _categories = categoriesSet.toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching blogs: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<dynamic> get featuredArticles => _blogs.where((b) => b['isFeatured'] == true).toList();
  List<dynamic> get latestArticles => _blogs.where((b) => b['isFeatured'] != true).toList();
  
  List<dynamic> get filteredLatestArticles {
    if (_selectedCategory == 'All') return latestArticles;
    return latestArticles.where((b) => b['category'] == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final bool isTablet = Responsive.isTablet(context);

    return OjasLayout(
      activeTitle: 'BLOG',
      child: Container(
        color: const Color(0xFFF8FAFC),
        padding: EdgeInsets.symmetric(vertical: isMobile ? 32 : 60),
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF01B6B)))
          : CenteredContent(
          horizontalPadding: isMobile ? 16 : 40,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Center(
                child: Column(
                  children: [
                    Text(
                      'Our Blog',
                      style: GoogleFonts.outfit(fontSize: isMobile ? 32 : 40, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Stay updated with the latest trends and insights',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: isMobile ? 14 : 16, color: const Color(0xFF475569)),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isMobile ? 32 : 48),

              // Search and Categories Layout
              if (isMobile)
                Column(
                  children: [
                    _buildSearchField(double.infinity),
                    const SizedBox(height: 16),
                    _buildCategories(context),
                  ],
                )
              else
                Row(
                  children: [
                    _buildSearchField(300),
                    const SizedBox(width: 24),
                    Expanded(child: _buildCategories(context)),
                  ],
                ),
              SizedBox(height: isMobile ? 40 : 64),

              // Featured Articles
              if (featuredArticles.isNotEmpty) ...[
                Text('Featured Articles', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                const SizedBox(height: 24),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: featuredArticles.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isMobile ? 1 : 2,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    mainAxisExtent: isMobile ? 480 : 470,
                  ),
                  itemBuilder: (context, index) => _BlogCard(article: featuredArticles[index], isFeatured: true, isMobile: isMobile),
                ),
                SizedBox(height: isMobile ? 48 : 64),
              ],

              // Latest Articles
              Text('Latest Articles', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
              const SizedBox(height: 24),
              if (filteredLatestArticles.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Text('No articles found in this category', style: GoogleFonts.inter(color: Colors.grey)),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredLatestArticles.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 3),
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    mainAxisExtent: 490,
                  ),
                  itemBuilder: (context, index) => _BlogCard(article: filteredLatestArticles[index], isFeatured: false, isMobile: isMobile),
                ),
              
              SizedBox(height: isMobile ? 48 : 80),

              // Subscribe Banner
              _buildSubscribeBanner(isMobile),
              
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(double width) {
    return Container(
      width: width,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF94A3B8), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search articles...',
                hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((cat) {
          bool isActive = cat == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => setState(() => _selectedCategory = cat),
              borderRadius: BorderRadius.circular(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFF01B6B) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isActive ? const Color(0xFFF01B6B) : const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  cat,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    color: isActive ? Colors.white : const Color(0xFF475569),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSubscribeBanner(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: isMobile ? 40 : 60, horizontal: isMobile ? 20 : 40),
      decoration: BoxDecoration(
        color: const Color(0xFFF01B6B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Stay Updated',
            style: GoogleFonts.outfit(fontSize: isMobile ? 24 : 32, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            'Subscribe to our newsletter for latest tips.',
            style: GoogleFonts.inter(fontSize: 15, color: Colors.white.withOpacity(0.9)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: isMobile ? double.infinity : 500,
            child: Flex(
              direction: isMobile ? Axis.vertical : Axis.horizontal,
              children: [
                Expanded(
                  flex: isMobile ? 0 : 1,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4105B),
                      borderRadius: isMobile ? BorderRadius.circular(8) : const BorderRadius.horizontal(left: Radius.circular(8)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter your email',
                        hintStyle: GoogleFonts.inter(color: Colors.white.withOpacity(0.6), fontSize: 14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                if (isMobile) const SizedBox(height: 12),
                Container(
                  height: 50,
                  width: isMobile ? double.infinity : null,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: isMobile ? BorderRadius.circular(8) : const BorderRadius.horizontal(right: Radius.circular(8)),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Subscribe',
                        style: GoogleFonts.inter(color: const Color(0xFFF01B6B), fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, color: Color(0xFFF01B6B), size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BlogCard extends StatelessWidget {
  final Map<String, dynamic> article;
  final bool isFeatured;
  final bool isMobile;

  const _BlogCard({required this.article, required this.isFeatured, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlogDetailPage(
              blogId: article['_id'],
              initialData: article,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: isFeatured ? 220 : 190,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    article['image'] ?? '', 
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
                    ),
                  ),
                  if (isFeatured)
                    Positioned(
                      top: 12, left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF01B6B),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('Featured', style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(article['category'] ?? 'General', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFF01B6B), fontWeight: FontWeight.bold)),
                        const SizedBox(width: 12),
                        Icon(Icons.access_time, size: 12, color: const Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Text(article['readingTime'] ?? '5 min read', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      article['title'] ?? 'Untitled',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold, 
                        color: const Color(0xFF0F172A),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      article['subtitle'] ?? article['content'] ?? '',
                      maxLines: isMobile ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B), height: 1.4),
                    ),
                    const Spacer(),
                    const Divider(color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: article['authorImage'] != null && article['authorImage'] != '' 
                                ? NetworkImage(article['authorImage']) 
                                : const NetworkImage('https://i.pravatar.cc/150?img=1'), 
                              radius: 10
                            ),
                            const SizedBox(width: 6),
                            Text(article['authorName'] ?? 'Admin', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF334155))),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.remove_red_eye_outlined, size: 12, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 4),
                            Text(article['views']?.toString() ?? '0', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
