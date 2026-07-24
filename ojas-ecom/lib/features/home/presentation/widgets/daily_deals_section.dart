
import 'package:ojas_user/core/constants/app_colors.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ojas_user/core/controllers/home_controller.dart';
import 'package:ojas_user/core/utils/responsive.dart';
import 'package:ojas_user/core/widgets/centered_content.dart';
import 'package:ojas_user/features/home/presentation/widgets/daily_deal_card.dart';
import 'package:ojas_user/features/home/domain/models/product_model.dart';

class DailyDealsSection extends StatefulWidget {
  const DailyDealsSection({super.key});

  @override
  State<DailyDealsSection> createState() => _DailyDealsSectionState();
}

class _DailyDealsSectionState extends State<DailyDealsSection> {
  int _currentIndex = 0;

  final CarouselSliderController _carouselController =
      CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: HomeController.instance,
      builder: (context, _) {
        final dailyDeals = HomeController.instance.dailyDealsProducts
            .map((p) => ProductModel.fromMap(p))
            .toList();

        final screenWidth = MediaQuery.of(context).size.width;

        final bool isMobile = Responsive.isMobile(context);

        /// RESPONSIVE ITEMS COUNT
        int itemsPerPage;

        if (screenWidth >= 1600) {
          itemsPerPage = 6;
        } else if (screenWidth >= 1100) {
          itemsPerPage = 3;
        } else if (screenWidth >= 700) {
          itemsPerPage = 2;
        } else {
          itemsPerPage = 1;
        }

        if (dailyDeals.length < itemsPerPage) {
          itemsPerPage = dailyDeals.length;
        }

        if (itemsPerPage == 0) {
          itemsPerPage = 1;
        }

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: isMobile ? 40 : 70),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF8FAFC), AppColors.white],
            ),
          ),
          child: CenteredContent(
            horizontalPadding: isMobile ? 16 : 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// HEADER
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryPink.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Text(
                                  'LIMITED TIME DEALS',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.primaryPink,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                             _CountdownTimerWidget(),
                            ],
                          ),

                          SizedBox(height: isMobile ? 14 : 18),

                          Text(
                            'Daily Deals',
                            style: GoogleFonts.outfit(
                              fontSize: isMobile ? 30 : 42,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111827),
                              height: 1.1,
                            ),
                          ),

                          const SizedBox(height: 10),

                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isMobile ? 500 : 700,
                            ),
                            child: Text(
                              'Explore premium furniture collections with modern designs crafted for comfort, style and productivity.',
                              style: GoogleFonts.inter(
                                fontSize: isMobile ? 14 : 16,
                                color: const Color(0xFF6B7280),
                                height: 1.7,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// NAV BUTTONS
                    if (dailyDeals.length > itemsPerPage && !isMobile)
                      Row(
                        children: [
                          _navButton(
                            Icons.arrow_back_rounded,
                            () => _carouselController.previousPage(),
                          ),

                          const SizedBox(width: 12),

                          _navButton(
                            Icons.arrow_forward_rounded,
                            () => _carouselController.nextPage(),
                          ),
                        ],
                      ),
                  ],
                ),

                SizedBox(height: isMobile ? 28 : 50),

                /// EMPTY STATE
                if (dailyDeals.isEmpty)
                  _emptyState()
                /// RESPONSIVE CAROUSEL
                else
               CarouselSlider.builder(
  carouselController: _carouselController,
  itemCount: (dailyDeals.length / itemsPerPage).ceil(),

  options: CarouselOptions(
    viewportFraction: 1,
    autoPlay: true,
    enlargeCenterPage: false,
    autoPlayInterval: const Duration(seconds: 5),

    /// FIXED RESPONSIVE HEIGHT
    height: isMobile ? 430 : 380,

    onPageChanged: (index, reason) {
      setState(() {
        _currentIndex = index;
      });
    },
  ),

  itemBuilder: (context, index, realIndex) {
    final int start = index * itemsPerPage;

    final int end = (index + 1) * itemsPerPage;

    final pageDeals = dailyDeals.sublist(
      start,
      end > dailyDeals.length
          ? dailyDeals.length
          : end,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < pageDeals.length; i++) ...[
          Expanded(
            child: DailyDealCard(
              product: pageDeals[i],
            ),
          ),

          if (i != pageDeals.length - 1)
            SizedBox(
              width: isMobile ? 14 : 24,
            ),
        ],

        /// FIX EMPTY GAP
        if (pageDeals.length < itemsPerPage)
          for (
            int i = 0;
            i < itemsPerPage - pageDeals.length;
            i++
          ) ...[
            const Expanded(
              child: SizedBox(),
            ),

            if (i !=
                itemsPerPage -
                        pageDeals.length -
                    1)
              SizedBox(
                width: isMobile ? 14 : 24,
              ),
          ],
      ],
    );
  },
),
               


                SizedBox(height: isMobile ? 24 : 40),

                /// DOTS
                if (dailyDeals.length > itemsPerPage)
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        (dailyDeals.length / itemsPerPage).ceil(),
                        (index) => _dot(_currentIndex == index, index),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _navButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        height: 52,
        width: 52,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.grey100),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF111827)),
      ),
    );
  }

  Widget _dot(bool active, int index) {
    return GestureDetector(
      onTap: () => _carouselController.animateToPage(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: active ? 28 : 8,
        height: 8,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: active ? AppColors.primaryPink : AppColors.grey300,
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 70),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(
            Icons.local_offer_outlined,
            size: 44,
            color: AppColors.grey400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Deals Available',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownTimerWidget extends StatefulWidget {
  const _CountdownTimerWidget();

  @override
  State<_CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<_CountdownTimerWidget> {
  late Duration _duration;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    _duration = endOfDay.difference(now);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_duration.inSeconds > 0) {
            _duration -= const Duration(seconds: 1);
          } else {
            _timer?.cancel();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final hours = _twoDigits(_duration.inHours);
    final minutes = _twoDigits(_duration.inMinutes.remainder(60));
    final seconds = _twoDigits(_duration.inSeconds.remainder(60));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.timer_outlined, color: AppColors.primaryPink, size: 14),
        const SizedBox(width: 6),
        _timeBox(hours),
        _colon(),
        _timeBox(minutes),
        _colon(),
        _timeBox(seconds),
      ],
    );
  }

  Widget _timeBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: AppColors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _colon() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        ':',
        style: GoogleFonts.inter(
          color: const Color(0xFF6B7280),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
