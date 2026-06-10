import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat/message_bubble.dart';
import '../widgets/chat/input_bar.dart';
import '../widgets/chat/hero_header.dart';
import '../widgets/chat/chat_header.dart';
import '../widgets/sidebar/sidebar_widget.dart';
import '../widgets/skeleton/chat_skeleton.dart';
import '../widgets/layout/responsive_layout.dart';

// Collapsed header height
const double _kHeaderHeight = 60.0;
// ListView bottom padding — keeps last message above the floating input bar
const double _kInputBarHeight = 110.0;
// Height of the gradient overlays at each edge
const double _kGradientHeight = 120.0;

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ChatProvider>();
      // Prevent wiping the chat state if we just navigated here while a message is actively sending (e.g., from onboarding)
      if (!provider.isSendingMessage) {
        provider.fetchSessions().then((_) {
          if (provider.activeChatId == null && provider.chats.isNotEmpty) {
            provider.selectChat(provider.chats.first.id);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients &&
          _scrollController.position.hasContentDimensions) {
        final pos = _scrollController.position;
        final isNearBottom = pos.maxScrollExtent - pos.pixels < 200;
        final isBeginning = pos.pixels == 0.0;
        if (isNearBottom || isBeginning) {
          _scrollController.jumpTo(pos.maxScrollExtent);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWide = ResponsiveLayout.isDesktop(context) || ResponsiveLayout.isTablet(context);

    return Consumer<ChatProvider>(
      builder: (context, provider, _) {
        final hasMessages =
            provider.activeMessages.isNotEmpty || provider.isTyping;

        if (hasMessages) _scrollToBottom();

        return Scaffold(
          backgroundColor: AppColors.bgDark,
          drawer: isWide ? null : const Drawer(child: SidebarWidget()),
          body: Row(
            children: [
              // ── Persistent sidebar on desktop ─────────────────────────
              if (isWide)
                Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      right: BorderSide(color: AppColors.borderDark, width: 1),
                    ),
                  ),
                  child: const SidebarWidget(),
                ),

              // ── Main area ─────────────────────────────────────────────
              Expanded(
                child: Stack(
                  children: [
                    // ── 1. Content (hero or messages) ──────────────────
                    Positioned.fill(
                      child: provider.isLoadingSessions
                          ? ChatSkeleton(isWide: isWide)
                          : hasMessages
                              ? _ChatContent(
                                  provider: provider,
                                  scrollController: _scrollController,
                                  isWide: isWide,
                                )
                              : HeroHeader(isWide: isWide),
                    ),

                    // ── 2. TOP gradient ──────────────────────────────────────
                    Positioned(
                      top: 0, left: 0, right: 0,
                      height: _kGradientHeight,
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.0, 0.5, 1.0],
                              colors: [
                                AppColors.bgDark,                          // solid
                                AppColors.bgDark.withValues(alpha: 0.70),  // 70%
                                Colors.transparent,                        // dissolves
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── 3. Header sits on top of gradient ─────────────────
                    Positioned(
                      top: 0, left: 0, right: 0,
                      child: ChatHeader(isWide: isWide),
                    ),

                    // ── 4. BOTTOM gradient: transparent → black (chat only) ──
                    if (hasMessages)
                      Positioned(
                        bottom: 0, left: 0, right: 0,
                        height: _kGradientHeight,
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: const [0.0, 0.45, 1.0],
                                colors: [
                                  Colors.transparent,
                                  AppColors.bgDark.withValues(alpha: 0.6),
                                  AppColors.bgDark,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                    // ── 5. Floating input bar ──────────────────────────
                    const Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: InputBar(),
                    ),

                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chat content — messages list with top/bottom room for gradient overlays
// ─────────────────────────────────────────────────────────────────────────────
class _ChatContent extends StatelessWidget {
  final ChatProvider provider;
  final ScrollController scrollController;
  final bool isWide;

  const _ChatContent({
    required this.provider,
    required this.scrollController,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    final messages = provider.activeMessages;
    final itemCount = messages.length + (provider.isTyping ? 1 : 0);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 850),
        child: ListView.builder(
          controller: scrollController,
          // Top padding clears the header + gradient, bottom clears the input bar
          padding: const EdgeInsets.fromLTRB(
              16, _kHeaderHeight + 64, 16, _kInputBarHeight),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            if (index == messages.length && provider.isTyping) {
              return const TypingIndicator();
            }
            return MessageBubble(message: messages[index], index: index);
          },
        ),
      ),
    );
  }
}
