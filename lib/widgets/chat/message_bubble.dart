import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app_theme.dart';
import '../../models/message.dart';
import '../../providers/chat_provider.dart';
import '../cards/startup_idea_card.dart';
import '../cards/task_card.dart';
import '../cards/roadmap_card.dart';
import '../cards/kangrow_score_card.dart';
import 'knowledge_source_badge.dart';

class MessageBubble extends StatefulWidget {
  final Message message;
  final int index;

  const MessageBubble({super.key, required this.message, required this.index});

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _showActions = false;
  bool _hasAnimated = false;

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Silently ignore if can't open
    }
  }

  List<InlineSpan> _parseInlineText(String text, TextStyle defaultStyle) {
    final List<InlineSpan> spans = [];
    int index = 0;

    while (index < text.length) {
      // Check for markdown link [text](url)
      if (text.startsWith('[', index)) {
        final closeBracket = text.indexOf(']', index + 1);
        if (closeBracket != -1 && closeBracket + 1 < text.length && text[closeBracket + 1] == '(') {
          final closeParen = text.indexOf(')', closeBracket + 2);
          if (closeParen != -1) {
            final linkText = text.substring(index + 1, closeBracket);
            final linkUrl = text.substring(closeBracket + 2, closeParen);
            final capturedUrl = linkUrl;
            spans.add(WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: GestureDetector(
                onTap: () => _launchUrl(capturedUrl),
                child: Text(
                  linkText,
                  style: defaultStyle.copyWith(
                    color: AppColors.lightCyan,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.lightCyan,
                  ),
                ),
              ),
            ));
            index = closeParen + 1;
            continue;
          }
        }
      }

      // Check for bold (**)
      if (text.startsWith('**', index)) {
        final end = text.indexOf('**', index + 2);
        if (end != -1) {
          final content = text.substring(index + 2, end);
          spans.add(TextSpan(
            text: content,
            style: defaultStyle.copyWith(fontWeight: FontWeight.bold),
          ));
          index = end + 2;
          continue;
        }
      }

      // Check for inline code (`)
      if (text.startsWith('`', index)) {
        final end = text.indexOf('`', index + 1);
        if (end != -1) {
          final content = text.substring(index + 1, end);
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                content,
                style: defaultStyle.copyWith(
                  fontFamily: 'monospace',
                  fontSize: defaultStyle.fontSize != null ? defaultStyle.fontSize! - 1 : 13,
                  color: AppColors.lightCyan,
                ),
              ),
            ),
          ));
          index = end + 1;
          continue;
        }
      }

      // Check for italic (*)
      if (text.startsWith('*', index)) {
        final end = text.indexOf('*', index + 1);
        if (end != -1) {
          final content = text.substring(index + 1, end);
          spans.add(TextSpan(
            text: content,
            style: defaultStyle.copyWith(fontStyle: FontStyle.italic),
          ));
          index = end + 1;
          continue;
        }
      }

      // regular character scanning - search starting from index + 1 to avoid finding the current character and looping infinitely
      int nextSpecial = text.length;
      final nextBold = text.indexOf('**', index + 1);
      final nextItalic = text.indexOf('*', index + 1);
      final nextCode = text.indexOf('`', index + 1);
      final nextLink = text.indexOf('[', index + 1);

      if (nextBold != -1 && nextBold < nextSpecial) nextSpecial = nextBold;
      if (nextItalic != -1 && nextItalic < nextSpecial) nextSpecial = nextItalic;
      if (nextCode != -1 && nextCode < nextSpecial) nextSpecial = nextCode;
      if (nextLink != -1 && nextLink < nextSpecial) nextSpecial = nextLink;

      spans.add(TextSpan(
        text: text.substring(index, nextSpecial),
        style: defaultStyle,
      ));
      index = nextSpecial;
    }

    return spans;
  }

  List<Widget> _parseMarkdownResponse(String rawText, {required bool isUser}) {
    final List<Widget> blocks = [];
    final lines = rawText.split('\n');

    final defaultStyle = TextStyle(
      color: isUser ? Colors.black : AppColors.textWhite,
      fontSize: 14,
      height: 1.45,
    );

    bool isInsideExpand = false;
    String expandTitle = '';
    final List<String> expandLines = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmedLine = line.trim();

      if (trimmedLine.isEmpty) {
        if (isInsideExpand) {
          expandLines.add(line);
        } else {
          if (blocks.isNotEmpty && blocks.last is! SizedBox) {
            blocks.add(const SizedBox(height: 8));
          }
        }
        continue;
      }

      // ─── IMAGE MARKDOWN PARSER ───
      final imageMatch = RegExp(r'!\[(.*?)\]\((.*?)\)').firstMatch(trimmedLine);
      if (imageMatch != null) {
        final alt = imageMatch.group(1) ?? '';
        final imageUrl = imageMatch.group(2) ?? '';
        if (imageUrl.isNotEmpty) {
          blocks.add(Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 150,
                        width: double.infinity,
                        color: Colors.white.withOpacity(0.05),
                        child: const Center(
                          child: CircularProgressIndicator(color: AppColors.lightCyan),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 100,
                        width: double.infinity,
                        color: Colors.white.withOpacity(0.05),
                        child: const Center(
                          child: Icon(Icons.broken_image_rounded, color: Colors.white38),
                        ),
                      );
                    },
                  ),
                ),
                if (alt.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    alt,
                    style: defaultStyle.copyWith(
                      fontSize: 11,
                      color: Colors.white54,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ));
          continue;
        }
      }

      // ─── SMART EXPANDABLE SECTIONS PARSER ───
      if (trimmedLine.startsWith('+++')) {
        if (!isInsideExpand) {
          isInsideExpand = true;
          expandTitle = trimmedLine.replaceFirst('+++', '').trim();
          if (expandTitle.isEmpty) expandTitle = 'More Information';
          expandLines.clear();
        } else {
          isInsideExpand = false;
          final String innerContent = expandLines.join('\n');
          final List<Widget> innerWidgets = _parseMarkdownResponse(innerContent, isUser: isUser);
          blocks.add(_ExpandableBlock(
            title: expandTitle,
            content: innerWidgets,
          ));
        }
        continue;
      }

      if (isInsideExpand) {
        expandLines.add(line);
        continue;
      }

      // ─── AI CALLOUT BLOCKS PARSER ───
      bool isCallout = false;
      String calloutEmoji = '';
      String calloutTitle = '';
      for (final emoji in ['💡', '📊', '⚠', '🚀', '📈', '📉', '🔥', '💰', '🎯']) {
        if (trimmedLine.startsWith(emoji)) {
          isCallout = true;
          calloutEmoji = emoji;
          calloutTitle = trimmedLine;
          break;
        }
      }

      if (isCallout) {
        final List<String> bodyLines = [];
        int j = i + 1;
        String sameLineContent = '';
        final colonIndex = trimmedLine.indexOf(':');
        if (colonIndex != -1 && colonIndex < trimmedLine.length - 1) {
          sameLineContent = trimmedLine.substring(colonIndex + 1).trim();
          calloutTitle = trimmedLine.substring(0, colonIndex).trim();
        }

        if (sameLineContent.isNotEmpty) {
          bodyLines.add(sameLineContent);
        }

        while (j < lines.length) {
          final nextLine = lines[j].trim();
          if (nextLine.isEmpty) {
            j++;
            break;
          }
          if (nextLine.startsWith('+++') || 
              nextLine.startsWith('#') || 
              ['💡', '📊', '⚠', '🚀', '📈', '📉', '🔥', '💰', '🎯'].any((e) => nextLine.startsWith(e))) {
            break;
          }
          bodyLines.add(lines[j]);
          j++;
        }

        i = j - 1;
        final bodyText = bodyLines.join('\n');
        final innerWidgets = _parseMarkdownResponse(bodyText, isUser: isUser);

        blocks.add(_CalloutBlock(
          emoji: calloutEmoji,
          title: calloutTitle,
          content: innerWidgets,
        ));
        continue;
      }

      // 1. Heading H1/H2
      if (line.startsWith('# ')) {
        blocks.add(Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: RichText(
            text: TextSpan(
              children: _parseInlineText(
                line.substring(2),
                defaultStyle.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ));
        continue;
      }
      if (line.startsWith('## ')) {
        blocks.add(Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: RichText(
            text: TextSpan(
              children: _parseInlineText(
                line.substring(3),
                defaultStyle.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ));
        continue;
      }
      if (line.startsWith('### ')) {
        blocks.add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: RichText(
            text: TextSpan(
              children: _parseInlineText(
                line.substring(4),
                defaultStyle.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ));
        continue;
      }

      // 3. Bullet List Item (starts with "- " or "* ")
      if (line.startsWith('- ') || line.startsWith('* ')) {
        blocks.add(Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '•  ',
                style: defaultStyle.copyWith(
                  color: isUser ? Colors.black : AppColors.lightCyan,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: _parseInlineText(
                      line.substring(2),
                      defaultStyle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
        continue;
      }

      // 4. Ordered List Item (starts with e.g. "1. ")
      final orderedListMatch = RegExp(r'^(\d+)\.\s+(.*)$').firstMatch(line);
      if (orderedListMatch != null) {
        final number = orderedListMatch.group(1);
        final content = orderedListMatch.group(2) ?? '';
        blocks.add(Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$number.  ',
                style: defaultStyle.copyWith(
                  color: isUser ? Colors.black : AppColors.lightCyan,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: _parseInlineText(
                      content,
                      defaultStyle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
        continue;
      }

      // 5. Follow-up suggestion chips (lines starting with →)
      // These are the natural follow-up questions the AI suggests at the end.
      if (trimmedLine.startsWith('→ ') || trimmedLine.startsWith('→ ')) {
        final suggestionText = trimmedLine.replaceFirst(RegExp(r'^→\s*'), '').trim();
        if (suggestionText.isNotEmpty) {
          blocks.add(Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 2),
            child: _FollowUpChip(text: suggestionText),
          ));
          continue;
        }
      }

      // 6. Normal Paragraph
      blocks.add(Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: RichText(
          text: TextSpan(
            children: _parseInlineText(
              line,
              defaultStyle,
            ),
          ),
        ),
      ));
    }

    if (isInsideExpand && expandLines.isNotEmpty) {
      final String innerContent = expandLines.join('\n');
      blocks.addAll(_parseMarkdownResponse(innerContent, isUser: isUser));
    }

    return blocks;
  }

  @override
  Widget build(BuildContext context) {
    final msg = widget.message;
    final isUser = msg.type == MessageType.user;

    Widget child;

    if (msg.type == MessageType.ideaCard) {
      child = Padding(
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
      );
    } else if (msg.type == MessageType.taskCard) {
      child = Padding(
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
      );
    } else if (msg.type == MessageType.validationCard) {
      child = Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.88,
            ),
            child: KangrowScoreCard(metadata: msg.metadata ?? {}),
          ),
        ),
      );
    } else if (msg.type == MessageType.roadmapCard) {
      child = Padding(
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
      );
    } else {
      // Extract Action Chips if assistant response
      final List<String> actionChips = [];
      String displayText = msg.text ?? '';

      // Extract Reasoning block if assistant response
      String? reasoningText;
      if (!isUser && displayText.isNotEmpty) {
        final reasoningRegex = RegExp(r'<reasoning>([\s\S]*?)<\/reasoning>');
        final match = reasoningRegex.firstMatch(displayText);
        if (match != null) {
          reasoningText = match.group(1)!.trim();
          displayText = displayText.replaceFirst(reasoningRegex, '').trim();
        }
      }

      if (!isUser && displayText.isNotEmpty) {
        final actionRegex = RegExp(r'^\[Action:\s*(.*?)\]$', multiLine: true);
        final matches = actionRegex.allMatches(displayText);
        for (final match in matches) {
          actionChips.add(match.group(1)!.trim());
        }
        displayText = displayText.replaceAll(actionRegex, '').trim();
      }

      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final isLastMessage = widget.index == chatProvider.activeMessages.length - 1;

      child = GestureDetector(
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
                        if (!isUser && ((msg.usedModules != null && msg.usedModules!.isNotEmpty) || (msg.metadata != null && msg.metadata!['knowledgeInjected'] == true)))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                if (msg.metadata != null && msg.metadata!['knowledgeInjected'] == true)
                                  const KnowledgeSourceBadge(),
                                if (msg.usedModules != null)
                                  ...msg.usedModules!.map((m) => _buildModuleBadge(m)),
                              ],
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (reasoningText != null && reasoningText.isNotEmpty) ...[
                                _ReasoningBlock(reasoning: reasoningText),
                                const SizedBox(height: 8),
                              ],
                              ..._parseMarkdownResponse(displayText, isUser: isUser),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!isUser && actionChips.isNotEmpty && isLastMessage) ...[
                const SizedBox(height: 12),
                _buildActionChips(context, actionChips),
              ],
              if (_showActions) _buildActionBar(displayText),
            ],
          ),
        ),
      );
    }

    if (!_hasAnimated) {
      _hasAnimated = true;
      if (msg.type == MessageType.ideaCard || msg.type == MessageType.taskCard) {
        return child
            .animate()
            .fadeIn(duration: 300.ms)
            .slideY(begin: 0.05, end: 0, duration: 250.ms);
      } else if (msg.type == MessageType.roadmapCard) {
        return child
            .animate()
            .fadeIn(duration: 200.ms)
            .slideY(begin: 0.05, end: 0, duration: 150.ms, curve: Curves.easeOutCubic);
      } else if (msg.type == MessageType.validationCard) {
        return child
            .animate()
            .fadeIn(duration: 300.ms)
            .slideY(begin: 0.05, end: 0, duration: 250.ms);
      } else {
        return child
            .animate()
            .fadeIn(duration: 200.ms)
            .slideX(
              begin: isUser ? 0.05 : -0.05,
              end: 0,
              duration: 200.ms,
              curve: Curves.easeOutCubic,
            );
      }
    }

    return child;
  }

  Widget _buildActionChips(BuildContext context, List<String> actions) {
    return Padding(
      padding: const EdgeInsets.only(left: 32, right: 12), // Align under message text
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: actions.map((action) {
          return InkWell(
            onTap: () {
              final chatProvider = Provider.of<ChatProvider>(context, listen: false);
              chatProvider.sendMessage(action);
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.lightCyan.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.lightCyan.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: AppColors.lightCyan,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    action,
                    style: const TextStyle(
                      color: AppColors.lightCyan,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
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
                'assets/logos/logo_without_text.png',
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
                'assets/logos/logo_without_text.png',
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

class _CalloutBlock extends StatelessWidget {
  final String emoji;
  final String title;
  final List<Widget> content;

  const _CalloutBlock({
    required this.emoji,
    required this.title,
    required this.content,
  });

  Color _getThemeColor() {
    switch (emoji) {
      case '💡':
      case '🎯':
        return AppColors.lightCyan;
      case '⚠':
        return AppColors.danger;
      case '📊':
      case '📈':
      case '🔥':
      case '💰':
        return AppColors.accentSuccess;
      case '📉':
        return Colors.amber;
      case '🚀':
      default:
        return AppColors.lightCyan;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getThemeColor();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(12),
          bottomRight: Radius.circular(12),
          topLeft: Radius.circular(4),
          bottomLeft: Radius.circular(4),
        ),
        border: Border(
          left: BorderSide(color: color, width: 3.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title.replaceFirst(emoji, '').trim(),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...content,
          ],
        ),
      ),
    );
  }
}

class _ExpandableBlock extends StatefulWidget {
  final String title;
  final List<Widget> content;

  const _ExpandableBlock({
    required this.title,
    required this.content,
  });

  @override
  State<_ExpandableBlock> createState() => _ExpandableBlockState();
}

class _ExpandableBlockState extends State<_ExpandableBlock> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.unfold_more_rounded,
                    size: 16,
                    color: AppColors.lightCyan,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AppColors.textGray,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(color: AppColors.borderDark, height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.content,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReasoningBlock extends StatefulWidget {
  final String reasoning;

  const _ReasoningBlock({required this.reasoning});

  @override
  State<_ReasoningBlock> createState() => _ReasoningBlockState();
}

class _ReasoningBlockState extends State<_ReasoningBlock> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.lightCyan.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.lightCyan.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.psychology_outlined,
                    size: 16,
                    color: AppColors.lightCyan,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "Co-Founder's Thought Process...",
                      style: TextStyle(
                        color: AppColors.lightCyan,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: AppColors.lightCyan,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Divider(color: AppColors.borderDark, height: 1),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                widget.reasoning,
                style: const TextStyle(
                  color: AppColors.textGray,
                  fontSize: 12.5,
                  height: 1.45,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FollowUpChip extends StatelessWidget {
  final String text;

  const _FollowUpChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6, top: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              final chatProvider = Provider.of<ChatProvider>(context, listen: false);
              chatProvider.sendMessage(text);
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.lightCyan.withValues(alpha: 0.3),
                  width: 1.2,
                ),
                color: AppColors.lightCyan.withValues(alpha: 0.05),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    text,
                    style: const TextStyle(
                      color: AppColors.lightCyan,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: AppColors.lightCyan,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

