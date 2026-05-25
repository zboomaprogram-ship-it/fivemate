import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingSlide> _slides = [
    OnboardingSlide(
      title: 'أهلاً بكِ في خامات',
      description: 'نوفر لكِ تشكيلة واسعة من قوالب السيليكون، خامات الريزن، والكونكريت بأفضل جودة وأسعار الجملة.',
      icon: Icons.auto_awesome,
    ),
    OnboardingSlide(
      title: 'تصفحّي واختاري خاماتك',
      description: 'أضيفي منتجاتك المفضلة وقوالب الميداليات، الدلايات، وأخشاب الهاند ميد بكل سهولة لسلتك.',
      icon: Icons.category_outlined,
    ),
    OnboardingSlide(
      title: 'طلب سريع عبر واتساب',
      description: 'أكدي طلبك بضغطة زر واحدة. سنقوم بصياغة الفاتورة وإرسالها فوراً لواتساب المتجر لتوصيل طلبك.',
      icon: Icons.send_to_mobile,
    ),
  ];

  void _onNext() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() {
    final prefsBox = Hive.box('prefs_box');
    prefsBox.put('onboarding_shown', true);
    context.go('/home');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topLeft,
              child: TextButton(
                onPressed: _finishOnboarding,
                child: const Text(
                  'تخطي',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        index == 0
                            ? Image.asset(
                                'assets/logo.png',
                                width: 140,
                                height: 140,
                                fit: BoxFit.contain,
                              )
                            : Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight.withOpacity(0.4),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  slide.icon,
                                  size: 80,
                                  color: AppColors.primary,
                                ),
                              ),
                        const SizedBox(height: 48),
                        Text(
                          slide.title,
                          style: AppTextStyles.display.copyWith(fontSize: 24),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          slide.description,
                          style: AppTextStyles.body.copyWith(fontSize: 15),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Footer dots and button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dot Indicators
                  Row(
                    children: List.generate(
                      _slides.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? AppColors.primary : AppColors.textLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  // CTA button
                  ElevatedButton(
                    onPressed: _onNext,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(120, 50),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                    child: Text(_currentPage == _slides.length - 1 ? 'ابدأ الآن' : 'التالي'),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class OnboardingSlide {
  final String title;
  final String description;
  final IconData icon;

  OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
  });
}
