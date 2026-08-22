import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  // ──────────────────────────────────────────────────────
  //  ثابت‌ها
  // ──────────────────────────────────────────────────────
  static const _emailDisplay = 'mohsen.faraji.dev@gmail.com';
  static const _emailLaunch = 'mohsen.faraji.dev@gmail.com';
  static const _appName = 'سودوکو';
  static const _appVersion = '۱.۰.۰';
  static const _developerName = 'محسن فرجی';
  static const _developerRole = 'توسعه‌دهنده اپلیکیشن سودوکو';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth >= 600;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ─── هدر ───
          _buildSliverAppBar(context, cs, textTheme),

          // ─── محتوا ───
          SliverToBoxAdapter(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 640 : double.infinity),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 32 : 20,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      _buildDeveloperInfo(context, cs, textTheme),
                      const SizedBox(height: 28),
                      _buildBioSection(context, cs, textTheme),
                      const SizedBox(height: 28),
                      _buildFeaturesSection(context, cs, textTheme),
                      const SizedBox(height: 28),
                      _buildContactSection(context, cs, textTheme),
                      const SizedBox(height: 32),
                      _buildFooter(context, cs, textTheme),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  //  هدر اسلایدری با گرادیانت غنی‌تر
  // ──────────────────────────────────────────────────────
  Widget _buildSliverAppBar(
    BuildContext context,
    ColorScheme cs,
    TextTheme textTheme,
  ) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      stretch: true,
      backgroundColor: cs.surface,
      leading: IconButton(
        tooltip: 'بازگشت',
        icon: const Icon(Icons.arrow_forward_ios_rounded),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                cs.primary.withValues(alpha: 0.85),
                cs.primary.withValues(alpha: 0.55),
                cs.surfaceContainerHighest.withValues(alpha: 0.3),
              ],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // الگوی شطرنجی ظریف
              CustomPaint(painter: _GridPainter(cs.outline.withValues(alpha: 0.06))),
              // دایره‌های تزئینی
              Positioned(
                top: -60,
                right: -40,
                child: _decorativeCircle(120, cs.onPrimary.withValues(alpha: 0.08)),
              ),
              Positioned(
                bottom: -30,
                left: -20,
                child: _decorativeCircle(80, cs.onPrimary.withValues(alpha: 0.06)),
              ),
              Positioned(
                top: 40,
                left: -10,
                child: _decorativeCircle(50, cs.onPrimary.withValues(alpha: 0.05)),
              ),
              // لوگو
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // حلقه درخشان دور لوگو
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: cs.onPrimary.withValues(alpha: 0.25),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: cs.onPrimary.withValues(alpha: 0.15),
                            ),
                            child: Icon(
                              Icons.grid_view_rounded,
                              size: 40,
                              color: cs.onPrimary.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _appName,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onPrimary,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  //  اطلاعات توسعه‌دهنده
  // ──────────────────────────────────────────────────────
  Widget _buildDeveloperInfo(
    BuildContext context,
    ColorScheme cs,
    TextTheme textTheme,
  ) {
    return Semantics(
      header: true,
      child: Center(
        child: Column(
          children: [
            Text(
              _developerName,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _developerRole,
                style: textTheme.titleSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  //  بخش «درباره»
  // ──────────────────────────────────────────────────────
  Widget _buildBioSection(
    BuildContext context,
    ColorScheme cs,
    TextTheme textTheme,
  ) {
    return Semantics(
      header: true,
      label: 'درباره توسعه‌دهنده',
      child: _SectionCard(
        icon: Icons.person_outline_rounded,
        title: 'درباره من',
        cs: cs,
        child: Text(
          'من یک توسعه‌دهنده موبایل هستم که عاشق بازی‌های استراتژیک و ریاضی هستم. '
          'این اپلیکیشن سودوکو را با عشق و تمرکز ساخته‌ام تا به کاربران امکان '
          'حل معمای سودوکو را با طراحی جذاب و کاربرپسند فراهم کنم.',
          textAlign: TextAlign.justify,
          style: textTheme.bodyLarge?.copyWith(
            height: 1.9,
            color: cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  //  بخش ویژگی‌های اپلیکیشن (جدید)
  // ──────────────────────────────────────────────────────
  Widget _buildFeaturesSection(
    BuildContext context,
    ColorScheme cs,
    TextTheme textTheme,
  ) {
    final features = [
      _Feature(
        icon: Icons.psychology_outlined,
        title: 'پازل هوشمند',
        description: 'تولید خودکار پازل با الگوریتم پیشرفته',
        color: Colors.blue,
      ),
      _Feature(
        icon: Icons.timer_outlined,
        title: 'چالش زمانی',
        description: 'رقابت با زمان در حالت‌های مختلف',
        color: Colors.deepOrange,
      ),
      _Feature(
        icon: Icons.emoji_events_outlined,
        title: 'ثبت رکورد',
        description: 'ذخیره بهترین زمان برای هر سطح',
        color: Colors.amber,
      ),
      _Feature(
        icon: Icons.calendar_today_outlined,
        title: 'چالش روزانه',
        description: 'پازل یکسان برای همه در هر روز',
        color: Colors.teal,
      ),
    ];

    return Semantics(
      header: true,
      label: 'ویژگی‌های اپلیکیشن',
      child: _SectionCard(
        icon: Icons.star_outline_rounded,
        title: 'ویژگی‌ها',
        cs: cs,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 440 ? 2 : 1;
            final spacing = 10.0;
            final itemWidth = columns > 1
                ? (constraints.maxWidth - spacing) / 2
                : constraints.maxWidth;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: features.map((f) {
                return SizedBox(
                  width: itemWidth,
                  child: _FeatureTile(feature: f, cs: cs, textTheme: textTheme),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  //  بخش ارتباط
  // ──────────────────────────────────────────────────────
  Widget _buildContactSection(
    BuildContext context,
    ColorScheme cs,
    TextTheme textTheme,
  ) {
    return Semantics(
      header: true,
      label: 'ارتباط با توسعه‌دهنده',
      child: _SectionCard(
        icon: Icons.mail_outline_rounded,
        title: 'ارتباط با من',
        cs: cs,
        child: _ContactTile(
          icon: Icons.email_rounded,
          title: 'ایمیل',
          subtitle: _emailDisplay,
          color: Colors.blue,
          onTap: () => _sendEmail(context),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  //  فوتر
  // ──────────────────────────────────────────────────────
  Widget _buildFooter(BuildContext context, ColorScheme cs, TextTheme textTheme) {
    return Center(
      child: Column(
        children: [
          Divider(
            color: cs.outlineVariant.withValues(alpha: 0.4),
            indent: 40,
            endIndent: 40,
          ),
          const SizedBox(height: 16),
          Text(
            'نسخه $_appVersion',
            style: textTheme.bodySmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite_rounded, color: Colors.red.shade400, size: 14),
              const SizedBox(width: 5),
              Text(
                'ساخته شده با فلاتر',
                style: textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  //  ارسال ایمیل
  // ──────────────────────────────────────────────────────
  void _sendEmail(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('در حال آماده‌سازی ایمیل...'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: cs.inverseSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );

    final uri = Uri(
      scheme: 'mailto',
      path: _emailLaunch,
      queryParameters: {'subject': 'پیام از اپلیکیشن سودوکو'},
    );
    await launchUrl(uri);
  }

  // ──────────────────────────────────────────────────────
  //  المان‌های کمکی
  // ──────────────────────────────────────────────────────
  Widget _decorativeCircle(double radius, Color color) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

// ════════════════════════════════════════════════════════
//  ویجت‌های کمکی (Private)
// ════════════════════════════════════════════════════════

/// کارت بخش با آیکون و عنوان
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.cs,
    required this.child,
  });

  final IconData icon;
  final String title;
  final ColorScheme cs;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.outline.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: cs.primary),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

/// آیتم ویژگی
class _Feature {
  const _Feature({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
}

class _FeatureTile extends StatefulWidget {
  const _FeatureTile({
    required this.feature,
    required this.cs,
    required this.textTheme,
  });

  final _Feature feature;
  final ColorScheme cs;
  final TextTheme textTheme;

  @override
  State<_FeatureTile> createState() => _FeatureTileState();
}

class _FeatureTileState extends State<_FeatureTile>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final f = widget.feature;
    return Semantics(
      button: true,
      label: '${f.title}: ${f.description}',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: f.color.withValues(alpha: _pressed ? 0.14 : 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: f.color.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: f.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(f.icon, size: 20, color: f.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        f.title,
                        style: widget.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: widget.cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        f.description,
                        style: widget.textTheme.bodySmall?.copyWith(
                          color: widget.cs.onSurfaceVariant,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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

/// آیتم ارتباط
class _ContactTile extends StatefulWidget {
  const _ContactTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_ContactTile> createState() => _ContactTileState();
}

class _ContactTileState extends State<_ContactTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: '${widget.title}: ${widget.subtitle}',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surface.withValues(alpha: _pressed ? 0.95 : 1.0),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.outline.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: _pressed ? 0.06 : 0.03),
                  blurRadius: _pressed ? 12 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.55),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: cs.onSurface.withValues(alpha: 0.25),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// نقاش الگوی شطرنجی ظریف در پس‌زمینه هدر
class _GridPainter extends CustomPainter {
  _GridPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

    const step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => old.color != color;
}
