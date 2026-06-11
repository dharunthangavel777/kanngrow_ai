import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app_theme.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/chat_provider.dart';
import '../../utils/india_cities.dart';
import '../chat_screen.dart';

class DynamicOnboardingScreen extends StatefulWidget {
  const DynamicOnboardingScreen({super.key});

  @override
  State<DynamicOnboardingScreen> createState() => _DynamicOnboardingScreenState();
}

class _DynamicOnboardingScreenState extends State<DynamicOnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _citySearchController = TextEditingController();
  int _currentIndex = 0;
  late AnimationController _loadingMsgController;
  int _loadingMsgIndex = 0;
  Timer? _autoAdvanceTimer;

  void _startAutoAdvance(OnboardingProvider provider) {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) {
        _nextPage(provider);
      }
    });
  }

  // Cycling messages for loading overlay
  static const List<String> _questionLoadingMessages = [
    'Analyzing your answers...',
    'Understanding your goals...',
    'Generating next question...',
    'Personalizing your journey...',
  ];

  static const List<String> _ideaLoadingMessages = [
    'Understanding your profile...',
    'Crafting your business idea...',
    'Tailoring to your market...',
    'Almost ready...',
  ];

  @override
  void initState() {
    super.initState();
    _loadingMsgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..addListener(() {
        if (_loadingMsgController.isCompleted) {
          setState(() {
            _loadingMsgIndex = (_loadingMsgIndex + 1) % _questionLoadingMessages.length;
          });
          _loadingMsgController.forward(from: 0);
        }
      });

    // Pre-fill name from Google auth
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<OnboardingProvider>();
      provider.preFillNameFromAuth();

      // If all questions are pre-filled (e.g. New Idea), skip straight to next
      if (provider.questions.isEmpty) {
        _nextPage(provider);
      } else if (!provider.isIdeaMode &&
                 _currentIndex == 0 &&
                 provider.answers['What\'s your full name?']?.isNotEmpty == true &&
                 provider.questions.length > 1) {
        // Skip the name question visually by jumping to the location page
        _pageController.jumpToPage(1);
        setState(() => _currentIndex = 1);
      }
    });
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _pageController.dispose();
    _textController.dispose();
    _citySearchController.dispose();
    _loadingMsgController.dispose();
    super.dispose();
  }

  void _startLoadingAnimation() {
    _loadingMsgIndex = 0;
    if (!_loadingMsgController.isAnimating) {
      _loadingMsgController.forward(from: 0);
    }
  }

  void _stopLoadingAnimation() {
    _loadingMsgController.stop();
  }

  Future<void> _nextPage(OnboardingProvider provider) async {
    // ── Duplicate prevention guard ───────────────────────────────────────────
    if (provider.isSubmitting) return;
    final chatProvider = context.read<ChatProvider>();

    final isLastKnownPage = provider.questions.isEmpty || _currentIndex >= provider.questions.length - 1;

    if (!isLastKnownPage) {
      _animateToNext();
      return;
    }

    // We are on the last current page — try to get next AI question
    provider.setSubmitting(true);
    _startLoadingAnimation();

    final wasEmptyBefore = provider.questions.isEmpty;
    final hasNext = await provider.generateNextQuestion();

    _stopLoadingAnimation();
    provider.setSubmitting(false);

    if (!mounted) return;

    if (hasNext) {
      // AI returned a new question
      if (!wasEmptyBefore) {
        _animateToNext();
      }
      return;
    }

    // No more questions — start idea generation
    provider.setSubmitting(true);
    _loadingMsgIndex = 0;
    _startLoadingAnimation();

    final prompt = provider.buildIdeaPrompt();

    try {
      if (provider.isIdeaMode) {
        await provider.completeIdeaOnboarding();
      } else {
        await provider.completeOnboardingOnBackend();
      }
    } catch (e) {
      if (!mounted) return;
      provider.setSubmitting(false);
      _stopLoadingAnimation();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!mounted) return;

    // Create chat session FIRST, then send message
    final hasExistingEmpty = chatProvider.chats.any(
      (c) => c.isIdea == true && c.messages.isEmpty,
    );

    if (!hasExistingEmpty) {
      await chatProvider.createNewChat(
        isIdea: true,
        title: provider.isIdeaMode ? 'New Business Idea' : 'My Business Idea',
      );
    }

    chatProvider.sendMessage(prompt, isIdeaPrompt: true);

    provider.setSubmitting(false);
    _stopLoadingAnimation();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, _) => const ChatScreen(),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
        (route) => false,
      );
    }
  }

  void _animateToNext() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousPage(OnboardingProvider provider) {
    if (provider.isSubmitting) return;
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      provider.cancelIdeaMode();
      Navigator.pop(context);
    }
  }

  void _onOptionSelected(
      OnboardingProvider provider, String questionTitle, String answerTitle) {
    if (provider.isSubmitting) return;
    provider.saveAnswer(questionTitle, answerTitle);
    _startAutoAdvance(provider);
  }

  void _onPageChanged(int index, OnboardingProvider provider) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _currentIndex = index);
      final question = provider.questions[index];
      if (question.type == 'text') {
        _textController.text = provider.answers[question.title]?.first ?? '';
      }
      if (question.type == 'text_search') {
        _citySearchController.clear();
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
                final showOverlay =
                    provider.isQuestionsLoading || provider.isGenerating || provider.isSubmitting;
                final isIdea = provider.isGenerating;

                return PopScope(
                  canPop: false,
                  onPopInvoked: (didPop) {
                    if (didPop) return;
                    _previousPage(provider);
                  },
                  child: Stack(
                    children: [
                      // ── Main Content ─────────────────────────────────────
                      Column(
                        children: [
                          // Progress Header
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24.0, vertical: 20),
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
                                    child: const Icon(
                                        Icons.arrow_back_rounded,
                                        color: Colors.white,
                                        size: 20),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: totalPages > 0
                                          ? (_currentIndex + 1) / (totalPages + (15 - provider.aiQuestionsAsked).clamp(0, 15)).clamp(1, 100)
                                          : 0,
                                      backgroundColor:
                                          Colors.white.withValues(alpha: 0.1),
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                              AppColors.lightCyan),
                                      minHeight: 6,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  '${_currentIndex + 1} of ${totalPages + (15 - provider.aiQuestionsAsked).clamp(0, 15)}',
                                  style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.5),
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          ),

                          Expanded(
                            child: PageView.builder(
                              controller: _pageController,
                              physics: const NeverScrollableScrollPhysics(),
                              onPageChanged: (i) => _onPageChanged(i, provider),
                              itemCount: provider.questions.length,
                              itemBuilder: (context, index) {
                                final question = provider.questions[index];
                                return _buildStep(provider, question);
                              },
                            ),
                          ),
                        ],
                      ),

                      // ── Blur + Skeleton Loading Overlay ──────────────────
                      if (showOverlay)
                        Positioned.fill(
                          child: ClipRect(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                color: AppColors.bgDark.withValues(alpha: 0.75),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Animated pulsing icon
                                      Container(
                                        width: 72,
                                        height: 72,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.lightCyan
                                              .withValues(alpha: 0.12),
                                          border: Border.all(
                                            color: AppColors.lightCyan
                                                .withValues(alpha: 0.4),
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.auto_awesome_rounded,
                                          color: AppColors.lightCyan,
                                          size: 32,
                                        ),
                                      )
                                          .animate(
                                              onPlay: (c) =>
                                                  c.repeat(reverse: true))
                                          .scaleXY(
                                              begin: 1.0,
                                              end: 1.12,
                                              duration: 900.ms,
                                              curve: Curves.easeInOut),
                                      const SizedBox(height: 28),
                                      AnimatedSwitcher(
                                        duration:
                                            const Duration(milliseconds: 400),
                                        transitionBuilder: (child, anim) =>
                                            FadeTransition(
                                                opacity: anim, child: child),
                                        child: Text(
                                          isIdea
                                              ? _ideaLoadingMessages[
                                                  _loadingMsgIndex %
                                                      _ideaLoadingMessages
                                                          .length]
                                              : _questionLoadingMessages[
                                                  _loadingMsgIndex %
                                                      _questionLoadingMessages
                                                          .length],
                                          key: ValueKey(_loadingMsgIndex),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Outfit',
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        isIdea
                                            ? 'Creating your personalized business idea...'
                                            : 'AI is crafting your next question',
                                        style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.55),
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 28),
                                      SizedBox(
                                        width: 200,
                                        child: LinearProgressIndicator(
                                          backgroundColor: Colors.white
                                              .withValues(alpha: 0.1),
                                          valueColor:
                                              const AlwaysStoppedAnimation(
                                                  AppColors.lightCyan),
                                          minHeight: 3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ).animate().fadeIn(duration: 250.ms),
                    ],
                  ),
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
                border: Border.all(
                    color: AppColors.lightCyan.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome_rounded,
                      color: AppColors.lightCyan, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'AI Generated',
                    style: TextStyle(
                        color: AppColors.lightCyan,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
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
            style:
                TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 15),
          ),
        ],
      );
    }

    Widget buildRightPane() {
      // ── Text Search (City Picker) ─────────────────────────────────────────
      if (question.type == 'text_search') {
        return _CitySearchField(
          controller: _citySearchController,
          selectedCity: answers.firstOrNull,
          onSelected: (city) {
            if (provider.isSubmitting) return;
            provider.saveAnswer(question.title, city);
            _startAutoAdvance(provider);
          },
        );
      }

      // ── Text Input ────────────────────────────────────────────────────────
      if (question.type == 'text') {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _textController,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              cursorColor: AppColors.lightCyan,
              textCapitalization: TextCapitalization.words,
              onChanged: (text) => provider.saveTextAnswer(question.title, text),
              decoration: InputDecoration(
                hintText: question.id == 'name' ? 'Enter your full name...' : 'Type here...',
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
          ],
        );
      }

      // ── Multi-select ──────────────────────────────────────────────────────
      if (question.type == 'multi') {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: question.options.map((opt) {
            final isSelected = answers.contains(opt['title']);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _OptionCard(
                title: opt['title'] as String,
                description: opt['desc'] as String,
                isSelected: isSelected,
                onTap: () {
                  if (provider.isSubmitting) return;
                  provider.toggleAnswer(question.title, opt['title'] as String);
                  _startAutoAdvance(provider);
                },
              ),
            );
          }).toList(),
        );
      }

      // ── Single select ────────────────────────────────────────────────────
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: question.options.map((opt) {
          final isSelected = answers.contains(opt['title']);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _OptionCard(
              title: opt['title'] as String,
              description: opt['desc'] as String,
              isSelected: isSelected,
              onTap: () => _onOptionSelected(provider, question.title, opt['title'] as String),
            ),
          );
        }).toList(),
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
              child: SingleChildScrollView(child: buildLeftPane()),
            ),
            const SizedBox(width: 48),
            Expanded(
              flex: 5,
              child: SingleChildScrollView(child: buildRightPane()),
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
    final isLoading = provider.isSubmitting;
    return GestureDetector(
      onTap: (isEnabled && !isLoading) ? () => _nextPage(provider) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isEnabled && !isLoading
              ? AppColors.lightCyan
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          boxShadow: (isEnabled && !isLoading)
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
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.black),
                  ),
                )
              : Text(
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

// ── City Search Picker ────────────────────────────────────────────────────────
class _CitySearchField extends StatefulWidget {
  final TextEditingController controller;
  final String? selectedCity;
  final ValueChanged<String> onSelected;

  const _CitySearchField({
    required this.controller,
    required this.onSelected,
    this.selectedCity,
  });

  @override
  State<_CitySearchField> createState() => _CitySearchFieldState();
}

class _CitySearchFieldState extends State<_CitySearchField> {
  List<String> _filtered = [];
  bool _showDropdown = false;

  void _onSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _filtered = [];
        _showDropdown = false;
      });
      return;
    }
    final q = query.toLowerCase();
    setState(() {
      _filtered = kIndiaCities.where((c) => c.toLowerCase().contains(q)).take(8).toList();
      _showDropdown = _filtered.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.selectedCity != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.lightCyan.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.lightCyan.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: AppColors.lightCyan, size: 18),
                  const SizedBox(width: 8),
                  Text(widget.selectedCity!, style: const TextStyle(color: AppColors.lightCyan, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        TextField(
          controller: widget.controller,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          cursorColor: AppColors.lightCyan,
          textCapitalization: TextCapitalization.words,
          onChanged: _onSearch,
          decoration: InputDecoration(
            hintText: 'Search city... (e.g. Bangalore)',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.lightCyan, size: 20),
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
        if (_showDropdown) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              children: _filtered.map((city) => InkWell(
                onTap: () {
                  widget.controller.clear();
                  setState(() => _showDropdown = false);
                  widget.onSelected(city);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(Icons.location_city_rounded, color: Colors.white.withValues(alpha: 0.5), size: 16),
                      const SizedBox(width: 12),
                      Text(city, style: const TextStyle(color: Colors.white, fontSize: 14)),
                    ],
                  ),
                ),
              )).toList(),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Option Card ───────────────────────────────────────────────────────────────
class _OptionCard extends StatelessWidget {
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.lightCyan.withValues(alpha: 0.1)
              : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.lightCyan.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.lightCyan.withValues(alpha: 0.1),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? AppColors.lightCyan : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.lightCyan, size: 20),
          ],
        ),
      ),
    );
  }
}
