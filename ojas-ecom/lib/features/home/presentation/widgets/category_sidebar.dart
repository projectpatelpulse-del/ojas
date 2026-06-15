import 'package:flutter/material.dart';
import 'package:ojas_user/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_user/core/controllers/home_controller.dart';

class CategorySidebar extends StatelessWidget {
  const CategorySidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: const BoxDecoration(
              color: Color(0xFFF01B6B), // Match the pinkish header in reference
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.list, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  'All Categories',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: HomeController.instance,
              builder: (context, _) {
                final categories = HomeController.instance.categories;

                if (HomeController.instance.isLoading && categories.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFF01B6B),
                      strokeWidth: 2,
                    ),
                  );
                }

                if (categories.isEmpty) {
                  return Center(
                    child: Text(
                      'No categories found',
                      style: GoogleFonts.inter(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  );
                }

                return Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: categories.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      indent: 20,
                      endIndent: 20,
                      color: Color(0xFFF1F5F9),
                    ),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final title = category['name'] ?? 'Unknown';
                      final List<dynamic> subcategories =
                          category['subcategories'] ?? [];

                      final String? imageUrl = category['image'];
                      Widget leadingWidget;
                      if (imageUrl != null && imageUrl.isNotEmpty) {
                        leadingWidget = ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            imageUrl,
                            width: 24,
                            height: 24,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.category_outlined,
                              size: 20,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      } else {
                        leadingWidget = const Icon(
                          Icons.category_outlined,
                          size: 20,
                          color: Colors.grey,
                        );
                      }

                      if (subcategories.isEmpty) {
                        return ListTile(
                          leading: leadingWidget,
                          title: Text(
                            title,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: Colors.grey,
                          ),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/shop',
                              arguments: {
                                'category': title,
                                'subcategory': 'All',
                              },
                            );
                          },
                          dense: true,
                          hoverColor: AppColors.bgSecondaryLight,
                        );
                      }

                      return ExpansionTile(
                        leading: leadingWidget,
                        title: Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        tilePadding: const EdgeInsets.only(left: 16, right: 16),
                        childrenPadding: const EdgeInsets.only(left: 12),
                        collapsedIconColor: Colors.grey,
                        iconColor: const Color(0xFFF01B6B),
                        children: subcategories.map((sub) {
                          return ListTile(
                            contentPadding: const EdgeInsets.only(
                              left: 48,
                              right: 16,
                            ),
                            title: Text(
                              sub['name'] ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/shop',
                                arguments: {
                                  'category': title,
                                  'subcategory': sub['name'] ?? '',
                                },
                              );
                            },
                            dense: true,
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
