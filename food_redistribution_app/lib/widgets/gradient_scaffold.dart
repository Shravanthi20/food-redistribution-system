import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_theme.dart';

/// A scaffold with a deep ocean gradient background
/// Use this as a replacement for Scaffold to get the themed background
class GradientScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final bool extendBodyBehindAppBar;
  final bool extendBody;
  final Color? backgroundColor;
  final List<Color>? gradientColors;
  final bool showAnimatedBackground;

  const GradientScaffold({
    Key? key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
    this.extendBodyBehindAppBar = true,
    this.extendBody = false,
    this.backgroundColor,
    this.gradientColors,
    this.showAnimatedBackground = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppTheme.primaryNavy,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors ?? [
              AppTheme.gradientStart,
              AppTheme.gradientMiddle,
              AppTheme.gradientEnd,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated background elements (optional)
            if (showAnimatedBackground) ...[
              _AnimatedBackgroundElements(),
            ],
            // Main scaffold content
            Scaffold(
              backgroundColor: Colors.transparent,
              appBar: appBar,
              body: body,
              floatingActionButton: floatingActionButton,
              floatingActionButtonLocation: floatingActionButtonLocation,
              bottomNavigationBar: bottomNavigationBar,
              drawer: drawer,
              endDrawer: endDrawer,
              extendBodyBehindAppBar: extendBodyBehindAppBar,
              extendBody: extendBody,
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated floating orbs for background decoration
class _AnimatedBackgroundElements extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Large cyan orb - top right
        Positioned(
          top: -100,
          right: -80,
          child: _GlowingOrb(
            size: 300,
            color: AppTheme.accentCyan.withOpacity(0.15),
          ),
        ),
        // Medium teal orb - center left
        Positioned(
          top: MediaQuery.of(context).size.height * 0.3,
          left: -120,
          child: _GlowingOrb(
            size: 250,
            color: AppTheme.accentTeal.withOpacity(0.1),
          ),
        ),
        // Small accent orb - bottom right
        Positioned(
          bottom: 100,
          right: -60,
          child: _GlowingOrb(
            size: 180,
            color: AppTheme.accentCyanSoft.withOpacity(0.12),
          ),
        ),
      ],
    );
  }
}

/// A glowing circular orb with blur effect
class _GlowingOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowingOrb({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: size * 0.5,
            spreadRadius: size * 0.1,
          ),
        ],
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color,
                  color.withOpacity(0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A customized app bar for the Deep Ocean theme
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final double elevation;
  final PreferredSizeWidget? bottom;

  const GlassAppBar({
    Key? key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.elevation = 0,
    this.bottom,
  }) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0),
  );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AppBar(
          title: titleWidget ?? (title != null ? Text(title!) : null),
          actions: actions,
          leading: leading,
          automaticallyImplyLeading: automaticallyImplyLeading,
          elevation: elevation,
          backgroundColor: AppTheme.surfaceGlassDark,
          bottom: bottom,
        ),
      ),
    );
  }
}

/// A floating action button with Deep Ocean styling
class GlassFAB extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;
  final bool extended;
  final String? label;

  const GlassFAB({
    Key? key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.extended = false,
    this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (extended && label != null) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label!),
        tooltip: tooltip,
        backgroundColor: AppTheme.accentTeal,
        foregroundColor: AppTheme.primaryNavy,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentTeal.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        tooltip: tooltip,
        backgroundColor: AppTheme.accentTeal,
        foregroundColor: AppTheme.primaryNavy,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon),
      ),
    );
  }
}

/// A dialog with Deep Ocean glassmorphism styling
class GlassDialog extends StatelessWidget {
  final String? title;
  final Widget? content;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? contentPadding;
  final EdgeInsetsGeometry? titlePadding;

  const GlassDialog({
    Key? key,
    this.title,
    this.content,
    this.actions,
    this.contentPadding,
    this.titlePadding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: AlertDialog(
          backgroundColor: AppTheme.primaryNavyLight.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: AppTheme.surfaceGlassBorder,
              width: 1,
            ),
          ),
          title: title != null
              ? Text(
                  title!,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : null,
          titlePadding: titlePadding ?? const EdgeInsets.fromLTRB(24, 24, 24, 0),
          content: content,
          contentPadding: contentPadding ?? const EdgeInsets.fromLTRB(24, 16, 24, 16),
          actions: actions,
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      ),
    );
  }

  /// Shows this dialog with proper animation
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    List<Widget>? actions,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => GlassDialog(
        title: title,
        content: content,
        actions: actions,
      ),
    );
  }
}

/// A bottom sheet with Deep Ocean styling
class GlassBottomSheet extends StatelessWidget {
  final Widget child;
  final bool showHandle;

  const GlassBottomSheet({
    Key? key,
    required this.child,
    this.showHandle = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.primaryNavyLight.withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: AppTheme.surfaceGlassBorder,
                width: 1,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showHandle) ...[
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceGlassBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }

  /// Shows this bottom sheet with proper animation
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    bool showHandle = true,
    bool isScrollControlled = false,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: isScrollControlled,
      builder: (context) => GlassBottomSheet(
        showHandle: showHandle,
        child: child,
      ),
    );
  }
}
