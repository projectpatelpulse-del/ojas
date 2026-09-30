import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_user/core/constants/app_colors.dart';
import 'package:ojas_user/core/controllers/home_controller.dart';
import 'package:ojas_user/features/home/domain/models/category_model.dart';
import 'package:ojas_user/features/home/presentation/widgets/category_item.dart';
import 'package:ojas_user/features/home/presentation/widgets/section_title.dart';
import 'package:ojas_user/core/widgets/centered_content.dart';

class CategoriesSection extends StatelessWidget {
  const CategoriesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: HomeController.instance,
      builder: (context, _) {
        final liveCategories = HomeController.instance.categories;

        final List<CategoryModel> categories = liveCategories.isNotEmpty
            ? liveCategories.map((c) {
                return CategoryModel(
                  id: (c['_id'] ?? c['id'] ?? '').toString(),
                  title: (c['name'] ?? '').toString(),
                  imageUrl: (c['image'] != null && c['image'].toString().isNotEmpty)
                      ? c['image'].toString()
                      : 'https://via.placeholder.com/150',
                  icon: c['icon']?.toString(),
                );
              }).toList()
            : CategoryModel.dummyCategories;

        if (categories.isEmpty) return const SizedBox.shrink();

        return CenteredContent(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 36.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle(
                  title: 'Shop by Category',
                  onSeeAll: () => Navigator.pushNamed(context, '/shop'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 20),
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final bool isBestSelling = index < liveCategories.length &&
                          (liveCategories[index]['isBestSelling'] == true);

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CategoryItem(category: cat),
                          if (isBestSelling)
                            Positioned(
                              top: -4,
                              right: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.3),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.local_fire_department, size: 10, color: Colors.white),
                                    const SizedBox(width: 2),
                                    Text(
                                      'HOT',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
