import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app_theme.dart';
import '../../models/message.dart';
import '../cards/startup_idea_card.dart';
import '../cards/task_card.dart';
import '../cards/roadmap_card.dart';

class MessageBubble extends StatefulWidget {
  final Message message;
  final int index;

  const MessageBubble({super.key, required this.message, required this.index});

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _showActions = false;

  @override
  Widget build(BuildContext context) {
    final msg = widget.message;

    if (msg.type == MessageType.ideaCard) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.88,
            ),
            child: StartupIdeaCard(metadata: msg.metadata ?? {}),
          ),
        ),
      )
          .animate()
          .fadeIn(duration: 300.ms)
          .slideY(begin: 0.05, end: 0, duration: 250.ms);
    }

    if (msg.type == MessageType.taskCard) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.88,
            ),
            child: TaskCardWidget(metadata: msg.metadata ?? {}),
          ),
        ),
      )
          .animate()
          .fadeIn(duration: 300.ms)
          .slideY(begin: 0.05, end: 0, duration: 250.ms);
    }

    if (msg.type == MessageType.roadmapCard) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.88,
            ),
            child: RoadmapCard(metadata: msg.metadata ?? {}),
          ),
        ),
      )
          .animate()
          .fadeIn(duration: 200.ms)
          .slideY(begin: 0.05, end: 0, duration: 150.ms, curve: Curves.easeOutCubic);
    }

    final isUser = msg.type == MessageType.user;

    return GestureDetector(
      onLongPress: () => setState(() => _showActions = !_showActions),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isUser) _buildAssistantAvatar(),
            Row(
              mainAxisAlignment:
                  isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isUser) const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      if (!isUser && msg.usedModules != null && msg.usedModules!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: msg.usedModules!.map((m) => _buildModuleBadge(m)).toList(),
                          ),
                        ),
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.78,
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: isUser
                          ? AppColors.messageUserBg
                          : Colors.transparent,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                      border: isUser
                          ? null
                          : Border.all(
                              color: AppColors.borderDark, width: 1),
                    ),
                    child: Text(
                      msg.text ?? '',
                      style: TextStyle(
                        color: isUser ? Colors.black : AppColors.textWhite,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ],
            ),
            if (_showActions) _buildActionBar(msg.text ?? ''),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 200.ms, delay: Duration(milliseconds: widget.index * 30))
        .slideX(
          begin: isUser ? 0.05 : -0.05,
          end: 0,
          duration: 200.ms,
          delay: Duration(milliseconds: widget.index * 30),
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildModuleBadge(String module) {
    IconData icon = Icons.check_circle_outline_rounded;
    if (module.contains('Idea')) icon = Icons.lightbulb_outline_rounded;
    if (module.contains('Validat')) icon = Icons.search_rounded;
    if (module.contains('Research')) icon = Icons.travel_explore_rounded;
    if (module.contains('Decision')) icon = Icons.psychology_rounded;
    if (module.contains('Competitor')) icon = Icons.stacked_bar_chart_rounded;
    if (module.contains('Plan')) icon = Icons.description_outlined;
    if (module.contains('Roadmap')) icon = Icons.map_outlined;
    if (module.contains('Launch')) icon = Icons.rocket_launch_outlined;
    if (module.contains('Growth')) icon = Icons.trending_up_rounded;
    if (module.contains('Memory')) icon = Icons.memory_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.lightCyan.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightCyan.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.lightCyan),
          const SizedBox(width: 4),
          Text(
            module,
            style: const TextStyle(
              color: AppColors.lightCyan,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantAvatar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.lightCyan, AppColors.lightCyanHover],
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/logos/logo.png',
                width: 24,
                height: 24,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text('Kangrow AI',
              style: TextStyle(
                  color: AppColors.textGray,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildActionBar(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ActionBtn(
            icon: Icons.copy_outlined,
            label: 'Copy',
            onTap: () {
              Clipboard.setData(ClipboardData(text: text));
              setState(() => _showActions = false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Copied to clipboard'),
                  backgroundColor: AppColors.cardBg,
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          _ActionBtn(
            icon: Icons.refresh_rounded,
            label: 'Retry',
            onTap: () => setState(() => _showActions = false),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionBtn(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppColors.textGray),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textGray, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.lightCyan, AppColors.lightCyanHover],
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/logos/logo.png',
                width: 24,
                height: 24,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Row(
              children: List.generate(
                3,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.lightCyan,
                      shape: BoxShape.circle,
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat())
                      .scale(
                        begin: const Offset(0.6, 0.6),
                        end: const Offset(1.2, 1.2),
                        duration: 400.ms,
                        delay: Duration(milliseconds: i * 100),
                        curve: Curves.easeInOut,
                      )
                      .then()
                      .scale(
                        begin: const Offset(1.2, 1.2),
                        end: const Offset(0.6, 0.6),
                        duration: 600.ms,
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
