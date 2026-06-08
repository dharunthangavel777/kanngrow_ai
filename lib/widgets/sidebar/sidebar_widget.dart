import 'package:flutter/material.dart';
import 'package:kangrow_ai/sheets/app_sheets.dart';
import 'package:provider/provider.dart';
import '../../app_theme.dart';
import '../../models/chat.dart';
import '../../providers/chat_provider.dart';
import '../chat/chat_header.dart';

class SidebarWidget extends StatelessWidget {
  const SidebarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    const double gradientHeight = 120.0;
    const double headerHeight = 60.0;

    return Container(
      width: 280,
      color: AppColors.bgDark,
      child: Stack(
        children: [
          // ── 1. Scrollable content ──────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // top pad for floating header
                const SizedBox(height: headerHeight + 4),

                // ── New Chat + Search as flat divider rows ────────────
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
                _NewChatRow(),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
                _SearchRow(),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.white.withValues(alpha: 0.06),
                ),

                // History list
                const Expanded(child: _ChatHistoryList()),

                // Bottom footer
                _SidebarFooter(),
              ],
            ),
          ),

          // ── 2. Top gradient: solid → 65% → transparent ────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: gradientHeight,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.5, 1.0],
                    colors: [
                      AppColors.bgDark,
                      AppColors.bgDark.withValues(alpha: 0.65),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── 3. Floating header ────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: ChatHeader(
                isWide: false,
                leading: const SizedBox(width: 44), // no menu icon
                title: const Text(
                  'Chats',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: const SizedBox(width: 44), // no pencil icon
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// New Chat — flat text row
// ─────────────────────────────────────────────────────────────────────────────
class _NewChatRow extends StatefulWidget {
  @override
  State<_NewChatRow> createState() => _NewChatRowState();
}

class _NewChatRowState extends State<_NewChatRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.read<ChatProvider>().createNewChat();
            if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
              Navigator.of(context).pop();
            }
          },
          splashColor: Colors.white.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  Icons.add_rounded,
                  color: _hovered
                      ? AppColors.lightCyan
                      : Colors.white.withValues(alpha: 0.55),
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text(
                  'New Chat',
                  style: TextStyle(
                    color: _hovered ? AppColors.lightCyan : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search — flat text row with inline TextField
// ─────────────────────────────────────────────────────────────────────────────
class _SearchRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: Colors.white.withValues(alpha: 0.3),
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              onChanged: (v) => context.read<ChatProvider>().setSearchQuery(v),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              cursorColor: AppColors.lightCyan,
              decoration: InputDecoration(
                hintText: 'Search chats...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.28),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                filled: true,
                fillColor: Colors.transparent,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chat history list with date groups
// ─────────────────────────────────────────────────────────────────────────────
class _ChatHistoryList extends StatelessWidget {
  const _ChatHistoryList();

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, provider, _) {
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            if (provider.todayChats.isNotEmpty) ...[
              _GroupLabel('Today'),
              ...provider.todayChats.map((c) => _ChatItem(chat: c)),
            ],
            if (provider.yesterdayChats.isNotEmpty) ...[
              _GroupLabel('Yesterday'),
              ...provider.yesterdayChats.map((c) => _ChatItem(chat: c)),
            ],
            if (provider.last7DaysChats.isNotEmpty) ...[
              _GroupLabel('Last 7 Days'),
              ...provider.last7DaysChats.map((c) => _ChatItem(chat: c)),
            ],
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String text;
  const _GroupLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.28),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single chat item
// ─────────────────────────────────────────────────────────────────────────────
class _ChatItem extends StatefulWidget {
  final Chat chat;
  const _ChatItem({required this.chat});

  @override
  State<_ChatItem> createState() => _ChatItemState();
}

class _ChatItemState extends State<_ChatItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final isSelected = provider.activeChatId == widget.chat.id;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {
          provider.selectChat(widget.chat.id);
          if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
            Navigator.of(context).pop();
          }
        },
        onLongPress: () => _showDeleteDialog(context, provider),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.cardBg
                : _hovered
                ? AppColors.cardBg.withValues(alpha: 0.5)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(
                    color: AppColors.lightCyan.withValues(alpha: 0.3),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 15,
                color: isSelected
                    ? AppColors.lightCyan
                    : AppColors.textLightGray,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.chat.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.textWhite
                        : AppColors.textGray,
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
              if (_hovered || isSelected)
                GestureDetector(
                  onTap: () => _showDeleteDialog(context, provider),
                  child: const Icon(
                    Icons.more_horiz_rounded,
                    size: 16,
                    color: AppColors.textGray,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, ChatProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Chat',
          style: TextStyle(color: AppColors.textWhite, fontSize: 16),
        ),
        content: Text(
          'Delete "${widget.chat.title}"?',
          style: const TextStyle(color: AppColors.textGray, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textGray),
            ),
          ),
          TextButton(
            onPressed: () {
              provider.deleteChat(widget.chat.id);
              Navigator.pop(ctx);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Footer — same card style as profile screen
// ─────────────────────────────────────────────────────────────────────────────
class _SidebarFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        ),
      ),
      child: Column(
        children: [
          _FooterCard(
            children: [
              _FooterRow(
                icon: Icons.shield_outlined,
                label: 'Privacy Policy',
                onTap: () => _openSheet(context, const PrivacyPolicySheet()),
              ),
              _FooterDivider(),
              _FooterRow(
                icon: Icons.lock_outline_rounded,
                label: 'Security',
                onTap: () => _openSheet(context, const SecuritySheet()),
              ),
              _FooterDivider(),
              _FooterRow(
                icon: Icons.workspace_premium_outlined,
                label: 'Upgrade to Pro',
                iconColor: AppColors.lightCyan,
                labelColor: AppColors.lightCyan,
                onTap: () => _openSheet(context, const PlanSheet()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openSheet(BuildContext context, Widget sheet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => sheet,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Footer card group (mirrors _Card from profile screen)
// ─────────────────────────────────────────────────────────────────────────────
class _FooterCard extends StatelessWidget {
  final List<Widget> children;
  const _FooterCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(children: children),
      ),
    );
  }
}

class _FooterRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;
  final Color? labelColor;
  final VoidCallback onTap;
  const _FooterRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Icon(
                icon,
                color: (iconColor ?? Colors.white).withValues(alpha: 0.55),
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: labelColor ?? Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.18),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      indent: 44,
      height: 1,
      thickness: 1,
      color: Colors.white.withValues(alpha: 0.06),
    );
  }
}
