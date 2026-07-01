import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../utils/screen_adapter.dart';
import '../main_controller.dart';

class PromoBanner extends StatelessWidget {
  const PromoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MainController>();
    return Obx(() {
      final banners = controller.banners.toList(growable: false);
      if (banners.isEmpty) {
        return const SizedBox.shrink();
      }
      return _PromoBannerCarousel(
        banners: banners,
        onTap: controller.handleBannerTap,
      );
    });
  }
}

class _PromoBannerCarousel extends StatefulWidget {
  const _PromoBannerCarousel({required this.banners, required this.onTap});

  final List<HomeBanner> banners;
  final ValueChanged<HomeBanner> onTap;

  @override
  State<_PromoBannerCarousel> createState() => _PromoBannerCarouselState();
}

class _PromoBannerCarouselState extends State<_PromoBannerCarousel> {
  late PageController _pageController;
  Timer? _timer;
  int _initialPage = 0;

  @override
  void initState() {
    super.initState();
    _resetController();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant _PromoBannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banners.length != widget.banners.length) {
      _timer?.cancel();
      _pageController.dispose();
      _resetController();
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _resetController() {
    _initialPage = widget.banners.length > 1 ? widget.banners.length * 1000 : 0;
    _pageController = PageController(initialPage: _initialPage);
  }

  void _startTimer() {
    if (widget.banners.length < 2) {
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_pageController.hasClients) {
        return;
      }
      final currentPage = _pageController.page?.round() ?? _initialPage;
      _pageController.animateToPage(
        currentPage + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final bannerWidth = MediaQuery.sizeOf(context).width - 40.w;
    final bannerHeight = bannerWidth * 96 / 335;
    return SizedBox(
      height: bannerHeight,
      child: Center(
        child: SizedBox(
          width: bannerWidth,
          height: bannerHeight,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.banners.length == 1 ? 1 : null,
            itemBuilder: (context, pageIndex) {
              final bannerIndex = pageIndex % widget.banners.length;
              final banner = widget.banners[bannerIndex];
              return GestureDetector(
                key: ValueKey('home_promo_banner_$bannerIndex'),
                behavior: HitTestBehavior.opaque,
                onTap: () => widget.onTap(banner),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.r),
                  child: Image.network(
                    banner.imageUrl,
                    width: bannerWidth,
                    height: bannerHeight,
                    fit: BoxFit.fill,
                    errorBuilder: (_, _, _) => const SizedBox.expand(),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
