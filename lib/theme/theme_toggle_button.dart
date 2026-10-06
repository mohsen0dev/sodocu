import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'theme_controller.dart';

/// دکمهٔ تغییر تم (تیره / روشن) با دو انیمیشن:
///
/// ۱. آیکون خورشید/ماه با چرخش و محوشدن نرم.
/// ۲. دایره‌ای که از مرکز دکمه روی کل صفحه گسترش می‌یابد، تم زیرش
///    تعویض می‌شود و سپس لایه شفاف می‌شود — یعنی تغییر تم بدون پرش
///    ناگهانی دیده می‌شود.
///
/// هیچ ارتباطی با منطق بازی ندارد.
class ThemeToggleButton extends StatefulWidget {
  const ThemeToggleButton({super.key});

  @override
  State<ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends State<ThemeToggleButton>
    with SingleTickerProviderStateMixin {
  /// پیشرفت دایره: ۰ → ۱ هنگام رشد، و بعد از تعویض تم ۱ → ۰ هنگام محوشدن.
  late final AnimationController _reveal;

  /// آیا مرحلهٔ محوشدن (شفاف شدن لایه) شروع شده است؟
  bool _fading = false;

  @override
  void initState() {
    super.initState();
    // در initState مقداردهی می‌شود تا هنگام dispose هرگز lazily
    // ساخته نشود (ساخت AnimationController روی المان غیرفعال خطا می‌دهد).
    _reveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
      reverseDuration: const Duration(milliseconds: 320),
    );
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    final next = ThemeController.mode.value == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;

    // موقعیت مرکز دکمه برای شروع دایره.
    final renderObject = context.findRenderObject();
    final box = renderObject is RenderBox &&
            renderObject.attached &&
            renderObject.hasSize
        ? renderObject
        : null;

    // اگر موقعیت در دسترس نبود، تم سریع و بدون دایره تعویض می‌شود.
    if (box == null) {
      await ThemeController.toggle();
      return;
    }

    final origin = box.localToGlobal(box.size.center(Offset.zero));
    final targetBg = next == ThemeMode.dark
        ? SudokuAppTheme.dark.scaffoldBackgroundColor
        : SudokuAppTheme.light.scaffoldBackgroundColor;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: _reveal,
          builder: (context, _) => CustomPaint(
            painter: _RevealPainter(
              center: origin,
              progress: _reveal.value,
              fading: _fading,
              color: targetBg,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );

    Overlay.of(context, rootOverlay: true).insert(entry);

    try {
      // ۱) دایره تا پوشاندن کل صفحه رشد می‌کند.
      await _reveal.forward();
      // ۲) تم زیر لایهٔ پوشاننده تعویض می‌شود.
      await ThemeController.set(next);
      // ۳) لایه به‌آرامی شفاف می‌شود تا تم جدید دیده شود.
      if (mounted) {
        setState(() => _fading = true);
        await _reveal.reverse();
      }
    } finally {
      entry.remove();
      if (mounted) {
        _fading = false;
        _reveal.value = 0;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, mode, _) {
        final isDark = mode == ThemeMode.dark;
        return IconButton(
          tooltip: 'تغیر تم',
          onPressed: _toggle,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, animation) => RotationTransition(
              turns: Tween<double>(begin: 0.5, end: 1).animate(animation),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.6, end: 1).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              ),
            ),
            child: Icon(
              isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
              key: ValueKey<bool>(isDark),
              color: isDark ? const Color(0xFF90CAF9) : Colors.amber,
            ),
          ),
        );
      },
    );
  }
}

/// نقاشِ دایرهٔ در حال گسترش (یا محوشونده) روی کل صفحه.
class _RevealPainter extends CustomPainter {
  const _RevealPainter({
    required this.center,
    required this.progress,
    required this.fading,
    required this.color,
  });

  /// مرکز دایره (مرکز دکمه در مختصات صفحه).
  final Offset center;

  /// پیشرفت انیمیشن (۰ تا ۱).
  final double progress;

  /// در مرحلهٔ محوشدن هستیم (شعاع ثابت، شفافیت کم می‌شود).
  final bool fading;

  /// رنگ پس‌زمینهٔ تم مقصد.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    // شعاع لازم برای پوشاندن گوشه‌های صفحه.
    final dx = math.max(center.dx, size.width - center.dx);
    final dy = math.max(center.dy, size.height - center.dy);
    final maxRadius = math.sqrt(dx * dx + dy * dy);

    final t = Curves.easeInOutCubic.transform(progress.clamp(0.0, 1.0));
    final radius = fading ? maxRadius : maxRadius * t;
    final opacity = fading ? progress : 1.0;

    canvas.drawCircle(
      center,
      radius,
      Paint()..color = color.withValues(alpha: opacity),
    );
  }

  @override
  bool shouldRepaint(_RevealPainter oldDelegate) =>
      oldDelegate.center != center ||
      oldDelegate.progress != progress ||
      oldDelegate.fading != fading ||
      oldDelegate.color != color;
}
