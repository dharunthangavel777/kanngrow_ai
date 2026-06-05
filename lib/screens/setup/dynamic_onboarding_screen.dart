import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app_theme.dart';
import '../../widgets/setup/wizard_option_card.dart';
import '../../widgets/skeleton/onboarding_skeleton.dart';
import '../../providers/onboarding_provider.dart';
import '../chat_screen.dart';

class DynamicOnboardingScreen extends StatefulWidget {
  const DynamicOnboardingScreen({super.key});

  @override
  State<DynamicOnboardingScreen> createState() => _DynamicOnboardingScreenState();
}

class _DynamicOnboardingScreenState extends State<DynamicOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage(OnboardingProvider provider) async {
    if (_currentIndex == provider.questions.length - 1) {
      final hasNext = await provider.generateNextQuestion();
      if (hasNext && mounted) {
        _animateToNext();
      } else {
        await provider.completeOnboardingOnBackend();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const ChatScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
            (route) => false,
          );
        }
      }
    } else if (_currentIndex < provider.questions.length - 1) {
      _animateToNext();
    }
  }

  void _animateToNext() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousPage(OnboardingProvider provider) {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _onOptionSelected(OnboardingProvider provider, String questionTitle, String answerTitle) {
    provider.saveAnswer(questionTitle, answerTitle);
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        _nextPage(provider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Consumer<OnboardingProvider>(
          builder: (context, provider, child) {
            final totalPages = provider.questions.length;
            final isGenerating = provider.isGenerating;

            return Stack(
              children: [
                Column(
                  children: [
                    // Progress Bar & Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => _previousPage(provider),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (_currentIndex + 1) / totalPages,
                                backgroundColor: Colors.white.withValues(alpha: 0.1),
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.lightCyan),
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '${_currentIndex + 1}/$totalPages',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        onPageChanged: (index) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() => _currentIndex = index);
                            }
                          });
                        },
                        itemCount: provider.questions.length,
                        itemBuilder: (context, index) {
                          final question = provider.questions[index];
                          return _buildStep(provider, question);
                        },
                      ),
                    ),
                  ],
                ),
                
                if (isGenerating)
                  Container(
                    color: AppColors.bgDark.withValues(alpha: 0.8),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const OnboardingSkeleton().animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                          const SizedBox(height: 24),
                          const Text(
                            'Analyzing your profile...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
                          const SizedBox(height: 8),
                          Text(
                            'AI is generating personalized follow-up questions',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 14,
                            ),
                          ).animate().fadeIn(delay: 400.ms),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 300.ms),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStep(OnboardingProvider provider, OnboardingQuestion question) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (question.isDynamic)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.lightCyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.lightCyan.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: AppColors.lightCyan, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'AI Generated',
                      style: TextStyle(
                        color: AppColors.lightCyan,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideX(begin: -0.1, end: 0),
            Text(
              question.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              question.subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
        ...question.options.map((opt) {
          final isSelected = provider.answers[question.title] == opt['title'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: WizardOptionCard(
              title: opt['title'] as String,
              description: opt['desc'] as String,
              icon: opt['icon'] as IconData,
              isSelected: isSelected,
              onTap: () => _onOptionSelected(provider, question.title, opt['title'] as String),
            ),
          );
        }),
      ],
    );
  }
}
