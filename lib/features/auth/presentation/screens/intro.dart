import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:ne3ma/core/constants/app_colors.dart';
import 'package:ne3ma/core/widgets/gasp_button.dart';

class IntroScreen extends ConsumerStatefulWidget {
  const IntroScreen({super.key});

  @override
  ConsumerState<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends ConsumerState<IntroScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  final List<Map<String, String>> introPages = [
    {
      'title': 'Share food. Save more.',
      'subtitle': 'Give your surplus food a second life through a safe, local, and trusted community network.',
      'image': 'assets/images/view-tasty-shawarma-dish 1.png',
    },
    {
      'title': 'Nearby food. On the way',
      'subtitle': 'Connect with nearby donors and get surplus food quickly, safely, and locally.',
      'image': 'assets/images/image 8.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemCount: introPages.length,
        itemBuilder: (context, index) {
          return _buildIntroPage(
            title: introPages[index]['title']!,
            subtitle: introPages[index]['subtitle']!,
            imagePath: introPages[index]['image']!,
          );
        },
      ),
    );
  }

  Widget _buildIntroPage({
    required String title,
    required String subtitle,
    required String imagePath,
  }) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset('assets/animations/NE3MA-SVG 1.svg', width: 150, height: 150),
                  const SizedBox(height: 24),
                  ClipOval(
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Pagination Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      introPages.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        width: _currentPage == index ? 12.0 : 8.0,
                        height: 8.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == index
                              ? AppColors.primaryLight
                              : Colors.grey[300],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Column(
              children: [
                GaspButton(
                  label: _currentPage == 0 ? 'Continue' : 'Get Started',
                  onPressed: () {
                    if (_currentPage == 0) {
                      // Go to next page (page 2)
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      // Navigate to SignUp page
                      context.go('/signup');
                    }
                  },
                  height: 60,
                  width: MediaQuery.of(context).size.width - 100,
                  textColor: Colors.white,
                  buttonColor: AppColors.primaryLight,
                  borderRadius: 30,
                ),
                const SizedBox(height: 12),
                GaspButton(
                  label: 'Sign Up',
                  onPressed: () {
                    context.go('/signup');
                  },
                  height: 60,
                  width: MediaQuery.of(context).size.width - 100,
                  textColor: AppColors.markerDry,
                  buttonColor: AppColors.accentSurface,
                  borderRadius: 30,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}