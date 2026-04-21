import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tournament_app/core/theme/app_colors.dart';
import 'package:tournament_app/core/theme/app_typography.dart';
import 'package:tournament_app/core/theme/app_theme.dart';

// ─── Pulsing LIVE badge ───────────────────────────────────────────────────────
/// Full-featured LIVE badge with double-ring pulse animation.
/// Drop in wherever you need the broadcast indicator.
class PulsingLiveBadge extends StatefulWidget {
  final bool showCount;
  final int? count;
  final double size;

  const PulsingLiveBadge({
    super.key,
    this.showCount = false,
    this.count,
    this.size = 8,
  });

  @override
  State<PulsingLiveBadge> createState() => _PulsingLiveBadgeState();
}

class _PulsingLiveBadgeState extends State<PulsingLiveBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat();
    _scale = Tween<double>(begin: 0.8, end: 1.8).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _opacity = Tween<double>(begin: 0.8, end: 0.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pulsing dot
        SizedBox(
          width: widget.size * 2.5,
          height: widget.size * 2.5,
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Stack(
              alignment: Alignment.center,
              children: [
                // Ripple ring
                Opacity(
                  opacity: _opacity.value,
                  child: Container(
                    width: widget.size * _scale.value,
                    height: widget.size * _scale.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.error.withOpacity(0.4),
                    ),
                  ),
                ),
                // Solid dot
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          widget.showCount && widget.count != null
              ? 'LIVE · ${widget.count}'
              : 'LIVE',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.error,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ─── CountdownTimer widget ────────────────────────────────────────────────────
/// Live countdown that ticks every second.
/// Shows "3d 2h", "1h 45m", "30m 10s", "Started" as appropriate.
class CountdownTimer extends StatefulWidget {
  final DateTime target;
  final TextStyle? style;
  final String prefix;

  const CountdownTimer({
    super.key,
    required this.target,
    this.style,
    this.prefix = '',
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _update();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _update());
  }

  void _update() {
    if (!mounted) return;
    final diff = widget.target.difference(DateTime.now());
    setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _label {
    if (_remaining == Duration.zero) return 'Started';
    final d = _remaining.inDays;
    final h = _remaining.inHours.remainder(24);
    final m = _remaining.inMinutes.remainder(60);
    final s = _remaining.inSeconds.remainder(60);
    if (d > 0) return '${widget.prefix}${d}d ${h}h';
    if (h > 0) return '${widget.prefix}${h}h ${m}m';
    return '${widget.prefix}${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _label,
      style: widget.style ?? AppTypography.labelMedium
          .copyWith(color: AppColors.primaryBrand),
    );
  }
}

// ─── NumberTicker ─────────────────────────────────────────────────────────────
/// Animated count-up number display. Used on PaymentSuccessScreen for queue#.
class NumberTicker extends StatefulWidget {
  final int target;
  final Duration duration;
  final TextStyle? style;

  const NumberTicker({
    super.key,
    required this.target,
    this.duration = const Duration(milliseconds: 1500),
    this.style,
  });

  @override
  State<NumberTicker> createState() => _NumberTickerState();
}

class _NumberTickerState extends State<NumberTicker>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) {
        final current = (_animation.value * widget.target).round();
        return Text(
          '#$current',
          style: widget.style ?? AppTypography.queueNumber,
        );
      },
    );
  }
}

// ─── SlidePageRoute ───────────────────────────────────────────────────────────
/// Right-to-left slide transition for manual push navigation.
/// go_router handles transitions automatically, but this is available
/// if you use Navigator.push anywhere.
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SlidePageRoute({required this.page})
      : super(
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, animation, __, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                  parent: animation, curve: Curves.easeInOut)),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
        );
}

// ─── ShakeWidget ──────────────────────────────────────────────────────────────
/// Wraps any child with a horizontal shake animation.
/// Call shakeKey.currentState?.shake() to trigger.
class ShakeWidget extends StatefulWidget {
  final Widget child;
  const ShakeWidget({super.key, required this.child});

  @override
  State<ShakeWidget> createState() => ShakeWidgetState();
}

class ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _anim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticIn));
  }

  void shake() => _ctrl.forward(from: 0);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) {
        final dx = _anim.value < 0.5
            ? _anim.value * 16
            : (1 - _anim.value) * 16;
        return Transform.translate(
          offset: Offset(dx * (_ctrl.value < 0.5 ? 1 : -1), 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ─── GoldProgressBar ──────────────────────────────────────────────────────────
/// Animated fill progress bar in brand gold. Use for spots remaining.
class GoldProgressBar extends StatefulWidget {
  final double value; // 0.0 to 1.0
  final double height;

  const GoldProgressBar({super.key, required this.value, this.height = 8});

  @override
  State<GoldProgressBar> createState() => _GoldProgressBarState();
}

class _GoldProgressBarState extends State<GoldProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _anim = Tween<double>(begin: 0, end: widget.value).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(GoldProgressBar old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _anim = Tween<double>(begin: _anim.value, end: widget.value).animate(
          CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => ClipRRect(
        borderRadius: BorderRadius.circular(widget.height / 2),
        child: LinearProgressIndicator(
          value: _anim.value.clamp(0.0, 1.0),
          minHeight: widget.height,
          backgroundColor: AppColors.divider,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBrand),
        ),
      ),
    );
  }
}
