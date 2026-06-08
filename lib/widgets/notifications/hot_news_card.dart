import 'package:flutter/material.dart';
import '../../app_theme.dart';

// ── Hot News Notification Card ────────────────────────────────────────────────
// Visually distinct from all other notification types.
// Renders a gradient fire header + expandable news items with colored tag chips.

class HotNewsCard extends StatefulWidget {
  final String notifId;
  final String hook;
  final List<Map<String, dynamic>> items;
  final String tier;
  final bool isRead;
  final String timeAgo;
  final VoidCallback onTap;

  const HotNewsCard({
    super.key,
    required this.notifId,
    required this.hook,
    required this.items,
    required this.tier,
    required this.isRead,
    required this.timeAgo,
    required this.onTap,
  });

  @override
  State<HotNewsCard> createState() => _HotNewsCardState();
}

class _HotNewsCardState extends State<HotNewsCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _shimmerAnim = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
    if (!widget.isRead) {
      _shimmerController.repeat();
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Color _tagColor(String tag) {
    switch (tag.toLowerCase()) {
      case 'market':
        return const Color(0xFF60A5FA);      // blue
      case 'opportunity':
        return const Color(0xFF34D399);      // emerald
      case 'risk':
        return const Color(0xFFF87171);      // red
      case 'trend':
        return const Color(0xFFA78BFA);      // violet
      case 'tool':
        return const Color(0xFF22D3EE);      // cyan
      default:
        return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onTap();
        setState(() => _expanded = !_expanded);
        if (widget.isRead) _shimmerController.stop();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.isRead
                ? AppColors.borderDark
                : const Color(0xFFFF6B00).withValues(alpha: 0.5),
            width: widget.isRead ? 1.0 : 1.8,
          ),
          boxShadow: widget.isRead
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFFFF6B00).withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Gradient Fire Header ─────────────────────────────────────
              _buildHeader(),

              // ── News Items ───────────────────────────────────────────────
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: _buildCollapsedPreview(),
                secondChild: _buildExpandedItems(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF6B00), Color(0xFFFFC107)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          // Fire icon with shimmer
          widget.isRead
              ? const Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.white,
                  size: 22,
                )
              : AnimatedBuilder(
                  animation: _shimmerAnim,
                  builder: (context, child) {
                    return ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: const [
                          Colors.white54,
                          Colors.white,
                          Colors.white54,
                        ],
                        stops: [
                          (_shimmerAnim.value - 0.3).clamp(0.0, 1.0),
                          _shimmerAnim.value.clamp(0.0, 1.0),
                          (_shimmerAnim.value + 0.3).clamp(0.0, 1.0),
                        ],
                      ).createShader(bounds),
                      child: child,
                    );
                  },
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.hook,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      widget.timeAgo,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _TierBadge(tier: widget.tier),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.items.length} insights',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!widget.isRead)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 8),
          Icon(
            _expanded
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            color: Colors.white,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedPreview() {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    final first = widget.items.first;
    final tag   = first['tag'] as String? ?? 'Market';
    return Container(
      color: AppColors.cardBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TagChip(tag: tag, color: _tagColor(tag)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              first['title'] as String? ?? '',
              style: TextStyle(
                color: widget.isRead ? AppColors.textGray : Colors.white,
                fontSize: 13,
                fontWeight:
                    widget.isRead ? FontWeight.w400 : FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Tap to expand',
            style: TextStyle(
              color: const Color(0xFFFFC107).withValues(alpha: 0.8),
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedItems() {
    return Container(
      color: AppColors.cardBg,
      child: Column(
        children: [
          for (int i = 0; i < widget.items.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: AppColors.borderDark,
                indent: 16,
                endIndent: 16,
              ),
            _buildNewsItem(widget.items[i]),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildNewsItem(Map<String, dynamic> item) {
    final title = item['title'] as String? ?? '';
    final body  = item['body']  as String? ?? '';
    final tag   = item['tag']   as String? ?? 'Market';
    final color = _tagColor(tag);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TagChip(tag: tag, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: widget.isRead ? Colors.white70 : Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              body,
              style: TextStyle(
                color: widget.isRead ? AppColors.textGray : Colors.white70,
                fontSize: 12.5,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Free-tier Teaser Card ─────────────────────────────────────────────────────

class HotNewsTeaserCard extends StatelessWidget {
  final VoidCallback onUpgradeTap;

  const HotNewsTeaserCard({super.key, required this.onUpgradeTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onUpgradeTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF1A0A00), Color(0xFF0D0F14)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: const Color(0xFFFF6B00).withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  color: Color(0xFFFF6B00),
                  size: 22,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Hot News — Upgrade to Unlock',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    color: Colors.white54,
                    size: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Get daily AI-curated business insights, personalised for your niche, industry trends, and market opportunities — delivered every morning.',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12.5,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B00), Color(0xFFFFC107)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  'Upgrade to Standard  →',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
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

// ── Helper Widgets ────────────────────────────────────────────────────────────

class _TagChip extends StatelessWidget {
  final String tag;
  final Color color;

  const _TagChip({required this.tag, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.8),
      ),
      child: Text(
        tag.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _TierBadge extends StatelessWidget {
  final String tier;
  const _TierBadge({required this.tier});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        tier.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
