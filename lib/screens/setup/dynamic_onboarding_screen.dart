import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app_theme.dart';
import '../../widgets/setup/wizard_option_card.dart';
import '../../widgets/skeleton/onboarding_skeleton.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/chat_provider.dart';
import '../chat_screen.dart';

class DynamicOnboardingScreen extends StatefulWidget {
  const DynamicOnboardingScreen({super.key});

  @override
  State<DynamicOnboardingScreen> createState() => _DynamicOnboardingScreenState();
}

class _DynamicOnboardingScreenState extends State<DynamicOnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _textController = TextEditingController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _nextPage(OnboardingProvider provider) async {
    final chatProvider = context.read<ChatProvider>();
    if (_currentIndex == provider.questions.length - 1) {
      final hasNext = await provider.generateNextQuestion();
      if (hasNext && mounted) {
        _animateToNext();
      } else {
        if (!mounted) return;
        final answersSummary = provider.visibleAnswers.entries
            .map((e) => '- ${e.key}: ${e.value.join(", ")}')
            .join('\n');
            
        final prompt = 'Based on my e-commerce profile, please generate a detailed, personalized e-commerce business idea for me. Here is my profile:\n$answersSummary';

        if (provider.isIdeaMode) {
          await provider.completeIdeaOnboarding();
          await chatProvider.createNewChat(isIdea: true, title: 'New Business Idea');
        } else {
          await provider.completeOnboardingOnBackend();
          await chatProvider.createNewChat(isIdea: true, title: 'My Business Idea');
        }

        chatProvider.sendMessage(prompt);

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

  void _onPageChanged(int index, OnboardingProvider provider) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _currentIndex = index);
        final question = provider.questions[index];
        if (question.type == 'text') {
          _textController.text = provider.answers[question.title]?.first ?? '';
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Align(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWide ? 950 : 600),
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
                                    value: totalPages > 0 ? (_currentIndex + 1) / totalPages : 0,
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
                            onPageChanged: (index) => _onPageChanged(index, provider),
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
        ),
      ),
    );
  }

  Widget _buildStep(OnboardingProvider provider, OnboardingQuestion question) {
    final answers = provider.answers[question.title] ?? [];
    final isWide = MediaQuery.of(context).size.width >= 768;

    Widget buildLeftPane() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
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
        ],
      );
    }

    Widget buildRightPane() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (question.type == 'text') ...[
            TextField(
              controller: _textController,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              cursorColor: AppColors.lightCyan,
              onChanged: (text) {
                provider.saveTextAnswer(question.title, text);
              },
              decoration: InputDecoration(
                hintText: 'Enter your answer...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                filled: true,
                fillColor: AppColors.surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.lightCyan),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              ),
            ),
            const SizedBox(height: 32),
            _buildContinueButton(provider, answers.isNotEmpty),
          ] else if (question.type == 'multi') ...[
            ...question.options.map((opt) {
              final isSelected = answers.contains(opt['title']);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: WizardOptionCard(
                  title: opt['title'] as String,
                  description: opt['desc'] as String,
                  icon: opt['icon'] as IconData,
                  isSelected: isSelected,
                  onTap: () {
                    provider.toggleAnswer(question.title, opt['title'] as String);
                  },
                ),
              );
            }),
            const SizedBox(height: 24),
            _buildContinueButton(provider, answers.isNotEmpty),
          ] else ...[
            ...question.options.map((opt) {
              final isSelected = answers.contains(opt['title']);
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
          ]
        ],
      );
    }

    if (isWide) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 5,
              child: SingleChildScrollView(
                child: buildLeftPane(),
              ),
            ),
            const SizedBox(width: 48),
            Expanded(
              flex: 5,
              child: SingleChildScrollView(
                child: buildRightPane(),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        buildLeftPane(),
        const SizedBox(height: 32),
        buildRightPane(),
      ],
    );
  }

  Widget _buildContinueButton(OnboardingProvider provider, bool isEnabled) {
    return GestureDetector(
      onTap: isEnabled ? () => _nextPage(provider) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isEnabled ? AppColors.lightCyan : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: AppColors.lightCyan.withValues(alpha: 0.2),
                    blurRadius: 12,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            'Continue',
            style: TextStyle(
              color: isEnabled ? Colors.black : Colors.white.withValues(alpha: 0.2),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
