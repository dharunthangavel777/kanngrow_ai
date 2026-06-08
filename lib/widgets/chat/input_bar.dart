import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_theme.dart';
import '../../providers/chat_provider.dart';

class InputBar extends StatefulWidget {
  const InputBar({super.key});

  @override
  State<InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<InputBar> {
  bool _hasText = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = context.read<ChatProvider>().inputController;
    _controller.addListener(_onTextChanged);
    // Initial check
    _onTextChanged();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context.read<ChatProvider>().sendMessage(text);
    _controller.clear();
    setState(() => _hasText = false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // ── Floating solid text field ────────────────────────────
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppColors.borderDark,
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Text input
                    Expanded(
                      child: TextField(
                        controller: _controller,
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
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          filled: false,
                        ),
                        onSubmitted: (v) {
                          if (v.trim().isNotEmpty) _send();
                        },
                      ),
                    ),
                    // Mic icon
                    _FieldIcon(icon: Icons.mic_none_rounded, onTap: () {}),
                    const SizedBox(width: 4),
                  ],
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
                color: _hasText ? AppColors.lightCyan : AppColors.cardBg,
                border: _hasText
                    ? null
                    : Border.all(
                        color: AppColors.borderDark,
                        width: 1,
                      ),
                boxShadow: _hasText
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
                  onTap: _hasText ? _send : null,
                  borderRadius: BorderRadius.circular(25),
                  child: Center(
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      color: _hasText
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
    );
  }
}

class _FieldIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _FieldIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.35),
          size: 20,
        ),
      ),
    );
  }
}

