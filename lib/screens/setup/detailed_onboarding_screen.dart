import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../widgets/setup/wizard_option_card.dart';
import 'business_dna_screen.dart';

class DetailedOnboardingScreen extends StatefulWidget {
  const DetailedOnboardingScreen({super.key});

  @override
  State<DetailedOnboardingScreen> createState() => _DetailedOnboardingScreenState();
}

class _DetailedOnboardingScreenState extends State<DetailedOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  // Form State
  String? _userType;
  String? _experienceLevel;
  String? _startupStage;
  String? _primaryGoal;

  final int _totalPages = 4;

  void _nextPage() {
    if (_currentIndex < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Proceed to Business DNA Setup
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const BusinessDnaScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  void _previousPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _onOptionSelected(VoidCallback updateState) {
    updateState();
    // Auto-advance smoothly after a short delay
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        _nextPage();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar & Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _previousPage,
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
                        value: (_currentIndex + 1) / _totalPages,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.lightCyan),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${_currentIndex + 1}/$_totalPages',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentIndex = index),
                children: [
                  _buildUserTypeStep(),
                  _buildExperienceStep(),
                  _buildStageStep(),
                  _buildGoalsStep(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
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
          subtitle,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildUserTypeStep() {
    final types = [
      {'title': 'Student', 'icon': Icons.school_outlined, 'desc': 'Exploring entrepreneurship'},
      {'title': 'Employee', 'icon': Icons.work_outline_rounded, 'desc': 'Looking to start a side hustle'},
      {'title': 'First-time Seller', 'icon': Icons.rocket_launch_outlined, 'desc': 'Building my first store'},
      {'title': 'Experienced Seller', 'icon': Icons.loop_rounded, 'desc': 'I have built stores before'},
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        _buildStepHeader('Who are you?', 'Tell us a bit about your background so we can tailor our advice.'),
        ...types.map((type) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: WizardOptionCard(
            title: type['title'] as String,
            description: type['desc'] as String,
            icon: type['icon'] as IconData,
            isSelected: _userType == type['title'],
            onTap: () => _onOptionSelected(() => setState(() => _userType = type['title'] as String)),
          ),
        )),
      ],
    );
  }

  Widget _buildExperienceStep() {
    final levels = [
      {'title': 'Beginner', 'icon': Icons.trending_flat_rounded, 'desc': 'I am new to e-commerce'},
      {'title': 'Intermediate', 'icon': Icons.trending_up_rounded, 'desc': 'I know the basics and have some experience'},
      {'title': 'Expert', 'icon': Icons.auto_graph_rounded, 'desc': 'I am well-versed in building and scaling businesses'},
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        _buildStepHeader('What is your experience level?', 'This helps the AI set the right tone and depth for answers.'),
        ...levels.map((level) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: WizardOptionCard(
            title: level['title'] as String,
            description: level['desc'] as String,
            icon: level['icon'] as IconData,
            isSelected: _experienceLevel == level['title'],
            onTap: () => _onOptionSelected(() => setState(() => _experienceLevel = level['title'] as String)),
          ),
        )),
      ],
    );
  }

  Widget _buildStageStep() {
    final stages = [
      {'title': 'Just a Product Concept', 'icon': Icons.lightbulb_outline_rounded, 'desc': 'I have a product in mind'},
      {'title': 'Building MVP', 'icon': Icons.construction_rounded, 'desc': 'I am actively building the first version'},
      {'title': 'Launched', 'icon': Icons.flight_takeoff_rounded, 'desc': 'Product is live with some users'},
      {'title': 'Scaling', 'icon': Icons.insights_rounded, 'desc': 'We are growing and generating revenue'},
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        _buildStepHeader('What stage are you at?', 'Let us know where your store currently stands.'),
        ...stages.map((stage) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: WizardOptionCard(
            title: stage['title'] as String,
            description: stage['desc'] as String,
            icon: stage['icon'] as IconData,
            isSelected: _startupStage == stage['title'],
            onTap: () => _onOptionSelected(() => setState(() => _startupStage = stage['title'] as String)),
          ),
        )),
      ],
    );
  }

  Widget _buildGoalsStep() {
    final goalsList = [
      {'title': 'Validate my Product', 'icon': Icons.fact_check_outlined},
      {'title': 'Find a Supplier', 'icon': Icons.people_outline_rounded},
      {'title': 'Build my Product', 'icon': Icons.architecture_rounded},
      {'title': 'Get Funding', 'icon': Icons.attach_money_rounded},
      {'title': 'Acquire Customers', 'icon': Icons.campaign_outlined},
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        _buildStepHeader('What is your primary goal?', 'Select your main focus so we can prioritize your roadmap.'),
        ...goalsList.map((goal) {
          final isSelected = _primaryGoal == goal['title'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: WizardOptionCard(
              title: goal['title'] as String,
              icon: goal['icon'] as IconData,
              isSelected: isSelected,
              onTap: () => _onOptionSelected(() => setState(() => _primaryGoal = goal['title'] as String)),
            ),
          );
        }),
      ],
    );
  }
}
