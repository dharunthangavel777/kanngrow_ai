import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_theme.dart';
import '../../providers/chat_provider.dart';
import '../../providers/user_provider.dart';

class InputBar extends StatefulWidget {
  const InputBar({super.key});

  @override
  State<InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<InputBar> {
  bool _hasText = false;
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = context.read<ChatProvider>().inputController;
    _controller.addListener(_onTextChanged);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChanged);
    // Initial check
    _onTextChanged();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus != _isFocused) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    final chatProvider = context.read<ChatProvider>();
    final pill = chatProvider.activeContextPill;
    
    if (text.isEmpty && pill == null) return;
    
    _controller.clear();
    setState(() => _hasText = false);
    
    final String fullText;
    if (pill != null) {
      if (text.isEmpty) {
        fullText = pill.prompt;
      } else {
        fullText = "${pill.prompt}\n\nDetails: $text";
      }
    } else {
      fullText = text;
    }
    
    try {
      await chatProvider.sendMessage(fullText);
      chatProvider.clearActiveContextPill();
      if (mounted) {
        context.read<UserProvider>().incrementLocalUsage();
      }
    } catch (e) {
      if (mounted) {
        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(e.toString(), style: const TextStyle(color: Colors.white))),
              ],
            ),
            backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
            behavior: SnackBarBehavior.floating,
            dismissDirection: DismissDirection.up,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: EdgeInsets.only(
              bottom: screenHeight - 120, // Push to top (adjust height)
              left: screenWidth > 600 ? screenWidth - 380 : 16, // Top right on desktop, top-full on mobile
              right: 16,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final canSend = _hasText || provider.activeContextPill != null;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 850),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // ── Floating solid text field ────────────────────────────
                Expanded(
                  child: CustomPaint(
                    painter: TinkeredBorderPainter(
                      color: _isFocused
                          ? AppColors.lightCyan
                          : AppColors.lightCyan.withValues(alpha: 0.35),
                      borderRadius: 24.0,
                      strokeWidth: _isFocused ? 3.0 : 2.0,
                      segmentLength: 35.0,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.borderDark,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Text input
                          TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            autofocus: false,
                            maxLines: 5,
                            minLines: 1,
                            textInputAction: TextInputAction.newline,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                            cursorColor: AppColors.lightCyan,
                            decoration: InputDecoration(
                              hintText: 'Ask anything about your ecommerce business...',
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.35),
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                              filled: false,
                            ),
                            onSubmitted: (v) {
                              if (v.trim().isNotEmpty || provider.activeContextPill != null) _send();
                            },
                          ),
                          
                          // Bottom Attachment Row
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                            child: Row(
                              children: [
                                // Plus button (Dropdown style)
                                _buildPlusDropdownButton(context),
                                const SizedBox(width: 8),

                                // Model Selector Dropdown (next to Plus button!)
                                const _ModelDropdown(),
                                const SizedBox(width: 8),

                                // Selected context pill
                                if (provider.activeContextPill != null)
                                  _SelectedContextPill(
                                    label: provider.activeContextPill!.label,
                                    icon: provider.activeContextPill!.icon,
                                    onRemove: () {
                                      provider.clearActiveContextPill();
                                    },
                                  ),
                                
                                const Spacer(),

                                // Mic icon
                                IconButton(
                                  icon: const Icon(Icons.mic_none_rounded, color: Colors.white54, size: 20),
                                  onPressed: () {},
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    
                const SizedBox(width: 10),
    
                // ── Floating send button ────────────────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: canSend ? AppColors.lightCyan : AppColors.cardBg,
                    border: canSend
                        ? null
                        : Border.all(
                            color: AppColors.borderDark,
                            width: 1,
                          ),
                    boxShadow: canSend
                        ? [
                            BoxShadow(
                              color: AppColors.lightCyan.withValues(alpha: 0.45),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: canSend ? _send : null,
                      borderRadius: BorderRadius.circular(25),
                      child: Center(
                        child: Icon(
                          Icons.arrow_upward_rounded,
                          color: canSend
                              ? Colors.black
                              : Colors.white.withValues(alpha: 0.4),
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlusDropdownButton(BuildContext context) {
    final provider = context.read<ChatProvider>();
    final pills = [
      const ContextPillModel(
        icon: Icons.lightbulb_outline_rounded,
        label: 'Product Idea',
        prompt: 'Help me generate a new e-commerce product idea.',
      ),
      const ContextPillModel(
        icon: Icons.check_circle_outline_rounded,
        label: 'Validate Idea',
        prompt: 'I want to validate my product idea.',
      ),
      const ContextPillModel(
        icon: Icons.rocket_launch_outlined,
        label: 'Launch Plan',
        prompt: 'Create a launch roadmap for my store.',
      ),
      const ContextPillModel(
        icon: Icons.trending_up_rounded,
        label: 'Marketing',
        prompt: 'Build a go-to-market strategy for my store.',
      ),
      const ContextPillModel(
        icon: Icons.shopping_cart_rounded,
        label: 'Sourcing',
        prompt: 'What\'s the best vendor sourcing strategy?',
      ),
    ];

    return PopupMenuButton<ContextPillModel>(
      icon: const Icon(Icons.add, color: Colors.white54, size: 20),
      tooltip: 'Attach Context',
      color: AppColors.surfaceDark,
      offset: const Offset(0, -260), // Opens nicely above the input bar
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderDark),
      ),
      onSelected: (p) {
        provider.setActiveContextPill(p);
      },
      itemBuilder: (BuildContext context) {
        return pills.map((p) {
          return PopupMenuItem<ContextPillModel>(
            value: p,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(p.icon, size: 16, color: AppColors.lightCyan),
                const SizedBox(width: 10),
                Text(
                  p.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
    );
  }
}

class _SelectedContextPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onRemove;

  const _SelectedContextPill({
    required this.label,
    required this.icon,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.lightCyan.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.lightCyan.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.lightCyan),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.lightCyan,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              size: 12,
              color: AppColors.lightCyan,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModelDropdown extends StatelessWidget {
  const _ModelDropdown();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final currentModel = provider.aiModel;

    String displayText = currentModel;
    if (currentModel.contains('GPT-4o-mini')) displayText = 'GPT-4o-mini';
    else if (currentModel.contains('GPT-4o')) displayText = 'GPT-4o';
    else if (currentModel.contains('GPT-3.5')) displayText = 'GPT-3.5';

    return PopupMenuButton<String>(
      tooltip: 'Select Model',
      color: AppColors.surfaceDark,
      offset: const Offset(0, -160), // Opens upwards (bottom to top)
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borderDark),
      ),
      onSelected: (String newValue) {
        provider.setAiModel(newValue);
      },
      itemBuilder: (BuildContext context) {
        return const [
          PopupMenuItem<String>(
            value: 'Fast (GPT-4o-mini)',
            child: Text('GPT-4o-mini', style: TextStyle(color: Colors.white, fontSize: 13)),
          ),
          PopupMenuItem<String>(
            value: 'Power (GPT-4o)',
            child: Text('GPT-4o', style: TextStyle(color: Colors.white, fontSize: 13)),
          ),
          PopupMenuItem<String>(
            value: 'Balanced (GPT-3.5)',
            child: Text('GPT-3.5', style: TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ];
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayText,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_up_rounded, // Arrow pointing up since it opens bottom-to-top!
              size: 16,
              color: Colors.white54,
            ),
          ],
        ),
      ),
    );
  }
}

class TinkeredBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;
  final double strokeWidth;
  final double segmentLength;

  TinkeredBorderPainter({
    required this.color,
    this.borderRadius = 24.0,
    this.strokeWidth = 1.5,
    this.segmentLength = 35.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final double w = size.width;
    final double h = size.height;
    final double r = borderRadius;

    // Top-Right Corner Path
    final trPath = Path()
      ..moveTo(w - segmentLength, 0)
      ..lineTo(w - r, 0)
      ..arcToPoint(
        Offset(w, r),
        radius: Radius.circular(r),
        clockwise: true,
      )
      ..lineTo(w, segmentLength);

    // Bottom-Left Corner Path
    final blPath = Path()
      ..moveTo(0, h - segmentLength)
      ..lineTo(0, h - r)
      ..arcToPoint(
        Offset(r, h),
        radius: Radius.circular(r),
        clockwise: true,
      )
      ..lineTo(segmentLength, h);

    canvas.drawPath(trPath, paint);
    canvas.drawPath(blPath, paint);
  }

  @override
  bool shouldRepaint(covariant TinkeredBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.segmentLength != segmentLength;
  }
}

