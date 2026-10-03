import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';

import '../home_controller.dart';

// ---------------------------------------------------------------------------
//  _AnimatedBoardNumber – عدد روی جدول با افکت جشن
// ---------------------------------------------------------------------------

class AnimatedBoardNumber extends StatefulWidget {
  const AnimatedBoardNumber({
    required this.number,
    required this.celebratingNumber,
    required this.celebrateRegion,
    required this.regionCelebrationToken,
    required this.fontSize,
    required this.fontWeight,
    required this.color,
    super.key,
  });

  final int number;
  final int? celebratingNumber;
  final bool celebrateRegion;
  final int regionCelebrationToken;
  final double fontSize;
  final FontWeight fontWeight;
  final Color color;

  @override
  State<AnimatedBoardNumber> createState() => _AnimatedBoardNumberState();
}

class _AnimatedBoardNumberState extends State<AnimatedBoardNumber>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  int _lastRegionToken = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 1.45), weight: 35),
      TweenSequenceItem(tween: Tween<double>(begin: 1.45, end: 1), weight: 65),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  void _runCelebration() {
    _controller.forward(from: 0);
  }

  @override
  void didUpdateWidget(AnimatedBoardNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    final animationsAllowed = !MediaQuery.of(context).disableAnimations;
    if (widget.celebratingNumber == widget.number &&
        oldWidget.celebratingNumber != widget.number &&
        animationsAllowed) {
      _runCelebration();
    }
    if (widget.celebrateRegion &&
        widget.regionCelebrationToken != _lastRegionToken &&
        animationsAllowed) {
      _lastRegionToken = widget.regionCelebrationToken;
      _runCelebration();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        final shake =
            sin(progress * pi * 12) * 5 * (1 - progress.clamp(0.0, 1.0));
        final isAnimating = _controller.isAnimating;

        return Transform.translate(
          offset: Offset(shake, 0),
          child: Transform.scale(
            scale: _scale.value,
            child: Text(
              widget.number.toString(),
              style: TextStyle(
                fontSize: widget.fontSize,
                fontWeight: widget.fontWeight,
                color: isAnimating ? const Color(0xFFFFD700) : widget.color,
                shadows: isAnimating
                    ? [
                        Shadow(
                          color: Colors.amber.shade700.withValues(alpha: 0.6),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
//  _AnimatedCellContainer – کانتینر خانه با افکت جشن و لرزش خطا
// ---------------------------------------------------------------------------

class AnimatedCellContainer extends StatefulWidget {
  const AnimatedCellContainer({
    required this.row,
    required this.col,
    required this.ctrl,
    required this.borderColor,
    required this.borderWidth,
    this.backgroundColor,
    this.mistakeFlashToken = 0,
    this.isMistake = false,
    required this.child,
    super.key,
  });

  final int row;
  final int col;
  final HomeController ctrl;
  final Color borderColor;
  final double borderWidth;
  final Color? backgroundColor;
  final int mistakeFlashToken;
  final bool isMistake;
  final Widget? child;

  @override
  State<AnimatedCellContainer> createState() => _AnimatedCellContainerState();
}

class _AnimatedCellContainerState extends State<AnimatedCellContainer>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _mistakeController;
  int _lastRegionToken = 0;
  int _lastMistakeToken = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _mistakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
  }

  Color _persistentBackground() {
    final completed = widget.ctrl.getCompletedUnitBackground(
      widget.row,
      widget.col,
    );
    final base = widget.backgroundColor;
    if (completed == null) {
      return base ?? Colors.transparent;
    }
    if (base == null) return completed;
    return Color.lerp(base, completed, 0.75) ?? completed;
  }

  Color _peakBackground() {
    return widget.ctrl.getCompletedUnitPeakBackground(widget.row, widget.col);
  }

  Color _celebrationColor(double progress) {
    final persistent = _persistentBackground();
    final peak = _peakBackground();
    final pulse = sin(progress * pi);
    return Color.lerp(persistent, peak, pulse * 0.95) ?? persistent;
  }

  @override
  void didUpdateWidget(AnimatedCellContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final animationsAllowed = !MediaQuery.of(context).disableAnimations;
    if (widget.ctrl.isCellCelebrating(widget.row, widget.col) &&
        widget.ctrl.celebrationToken.value != _lastRegionToken &&
        animationsAllowed) {
      _lastRegionToken = widget.ctrl.celebrationToken.value;
      _controller.forward(from: 0);
    }
    if (widget.isMistake && widget.mistakeFlashToken != _lastMistakeToken) {
      _lastMistakeToken = widget.mistakeFlashToken;
      if (!MediaQuery.of(context).disableAnimations) {
        _mistakeController.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _mistakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _mistakeController]),
      builder: (context, child) {
        final progress = _controller.value;
        final mistakeProgress = _mistakeController.value;
        final isCelebrating = widget.ctrl.isCellCelebrating(
          widget.row,
          widget.col,
        );
        final isMistakeAnimating = _mistakeController.isAnimating;

        final persistent = _persistentBackground();
        final base = persistent == Colors.transparent ? null : persistent;
        final bgColor = isMistakeAnimating
            ? Color.lerp(
                base ?? Colors.transparent,
                Colors.red,
                0.35 * (1 - mistakeProgress),
              )
            : (_controller.isAnimating || isCelebrating
                  ? _celebrationColor(progress)
                  : persistent);

        final shake = isMistakeAnimating
            ? sin(mistakeProgress * pi * 8) * 6 * (1 - mistakeProgress)
            : 0.0;

        return Transform.translate(
          offset: Offset(shake, 0),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isMistakeAnimating ? Colors.red : widget.borderColor,
                width: isMistakeAnimating ? 2 : widget.borderWidth,
              ),
              color: bgColor == Colors.transparent ? null : bgColor,
              boxShadow: _controller.isAnimating
                  ? [
                      BoxShadow(
                        color: Colors.amber.withValues(
                          alpha: 0.35 * (1 - progress),
                        ),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
//  BounceOnChange – عددی با پرش هنگام تغییر (برای screen reader)
// ---------------------------------------------------------------------------

class BounceOnChange extends StatefulWidget {
  const BounceOnChange({required this.value, this.announcement, super.key});

  final String value;
  final String? announcement;

  @override
  State<BounceOnChange> createState() => _BounceOnChangeState();
}

class _BounceOnChangeState extends State<BounceOnChange>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(BounceOnChange oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value &&
        !MediaQuery.of(context).disableAnimations) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: widget.announcement ?? widget.value,
      child: ScaleTransition(
        scale: _scale,
        child: Text(
          widget.value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
