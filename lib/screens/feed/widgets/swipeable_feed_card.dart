import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../models/feed_user.dart';
import 'feed_card.dart';

/// Верхняя карточка поиска: плавный свайп, пружина при отмене, вылет при лайке/дизлайке.
class SwipeableFeedCard extends StatefulWidget {
  const SwipeableFeedCard({
    super.key,
    required this.user,
    required this.onSwipe,
    required this.onOpenProfile,
  });

  final FeedUser user;
  final void Function(bool isLike) onSwipe;
  final VoidCallback onOpenProfile;

  @override
  State<SwipeableFeedCard> createState() => _SwipeableFeedCardState();
}

class _SwipeableFeedCardState extends State<SwipeableFeedCard> with SingleTickerProviderStateMixin {
  static const double _threshold = 88;

  double _dx = 0;
  late AnimationController _ac;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 320))
      ..addListener(_tick)
      ..addStatusListener(_onAnimStatus);
  }

  void _tick() {
    if (!mounted) return;
    setState(() {});
  }

  double _animStart = 0;
  double _animEnd = 0;
  Curve _animCurve = Curves.easeOutCubic;
  VoidCallback? _afterAnim;

  void _onAnimStatus(AnimationStatus s) {
    if (s == AnimationStatus.completed) {
      _afterAnim?.call();
      _afterAnim = null;
      _ac.reset();
    }
  }

  void _runAnimation(double from, double to, Duration duration, Curve curve, VoidCallback? then) {
    _ac.stop();
    _ac.duration = duration;
    _animStart = from;
    _animEnd = to;
    _animCurve = curve;
    _afterAnim = then;
    _ac.forward(from: 0);
  }

  double get _offset {
    if (!_ac.isAnimating) return _dx;
    final t = _animCurve.transform(_ac.value);
    return _animStart + (_animEnd - _animStart) * t;
  }

  @override
  void didUpdateWidget(covariant SwipeableFeedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.uid != widget.user.uid) {
      _ac.stop();
      _dx = 0;
    }
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_ac.isAnimating) return;
    setState(() => _dx += d.delta.dx);
  }

  void _onPanEnd(DragEndDetails details, double maxW) {
    if (_ac.isAnimating) return;
    final x = _dx;
    if (x.abs() > _threshold) {
      final out = x > 0 ? maxW * 1.35 : -maxW * 1.35;
      _runAnimation(
        x,
        out,
        const Duration(milliseconds: 260),
        Curves.easeInCubic,
        () {
          widget.onSwipe(x > 0);
          if (mounted) setState(() => _dx = 0);
        },
      );
    } else {
      _runAnimation(
        x,
        0,
        Duration(milliseconds: (220 + x.abs() * 0.4).round().clamp(200, 380)),
        Curves.easeOutBack,
        () {
          if (mounted) setState(() => _dx = 0);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final x = _ac.isAnimating ? _offset : _dx;
    final progress = (x.abs() / _threshold).clamp(0.0, 1.0);
    final rot = x * 0.00025;

    return GestureDetector(
      onHorizontalDragUpdate: _onPanUpdate,
      onHorizontalDragEnd: (d) => _onPanEnd(d, w),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Мягкие градиенты по краям
          Positioned.fill(
            child: IgnorePointer(
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: w * 0.45,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            const Color(0xFFE53935).withValues(alpha: 0.22 * progress * (x < 0 ? 1 : 0.15)),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: w * 0.45,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                          colors: [
                            const Color(0xFFE91E63).withValues(alpha: 0.22 * progress * (x > 0 ? 1 : 0.15)),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(x, 0),
            child: Transform.rotate(
              angle: rot,
              child: Transform.scale(
                scale: 1.0 - 0.04 * progress,
                child: FeedCard(
                  user: widget.user,
                  onTapArrow: widget.onOpenProfile,
                  onTapPhoto: widget.onOpenProfile,
                ),
              ),
            ),
          ),
          if (x < -16)
            Positioned(
              left: 20,
              child: _SwipeBadge(
                icon: Icons.close_rounded,
                color: const Color(0xFFE53935),
                opacity: math.min(1.0, -x / _threshold),
              ),
            ),
          if (x > 16)
            Positioned(
              right: 20,
              child: _SwipeBadge(
                icon: Icons.favorite_rounded,
                color: const Color(0xFFE91E63),
                opacity: math.min(1.0, x / _threshold),
              ),
            ),
        ],
      ),
    );
  }
}

class _SwipeBadge extends StatelessWidget {
  const _SwipeBadge({
    required this.icon,
    required this.color,
    required this.opacity,
  });

  final IconData icon;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.9), width: 2.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icon, size: 52, color: color),
      ),
    );
  }
}
