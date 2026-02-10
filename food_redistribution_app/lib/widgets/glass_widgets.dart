import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// A container with a frosted glass (glassmorphism) effect
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurAmount;
  final bool showBorder;
  final Color? tintColor;
  final VoidCallback? onTap;

  const GlassContainer({
    Key? key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.blurAmount = 10,
    this.showBorder = true,
    this.tintColor,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget container = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (tintColor ?? Colors.white).withOpacity(0.1),
                (tintColor ?? Colors.white).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: showBorder
                ? Border.all(
                    color: AppTheme.surfaceGlassBorder,
                    width: 1.5,
                  )
                : null,
          ),
          child: child,
        ),
      ),
    );

    if (margin != null) {
      container = Padding(padding: margin!, child: container);
    }

    if (onTap != null) {
      container = GestureDetector(onTap: onTap, child: container);
    }

    return container;
  }
}

/// A card with glassmorphism styling
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool isAccent;

  const GlassCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.isAccent = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8),
      tintColor: isAccent ? AppTheme.accentTeal : null,
      onTap: onTap,
      child: child,
    );
  }
}

/// A gradient button with glow effect
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final IconData? icon;
  final List<Color>? gradientColors;
  final bool outlined;

  const GradientButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.width,
    this.icon,
    this.gradientColors,
    this.outlined = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ?? [AppTheme.accentTeal, AppTheme.accentTealLight];

    if (outlined) {
      return Container(
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colors.first,
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              child: _buildContent(colors.first),
            ),
          ),
        ),
      );
    }

    return Container(
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
            child: _buildContent(AppTheme.primaryNavy),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Color textColor) {
    if (isLoading) {
      return Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(textColor),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// A text field with glassmorphism styling
class GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final String? Function(String?)? validator;
  final int? maxLines;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  const GlassTextField({
    Key? key,
    required this.controller,
    this.label,
    this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.prefixIcon,
    this.validator,
    this.maxLines = 1,
    this.enabled = true,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              obscureText: obscureText,
              validator: validator,
              maxLines: maxLines,
              enabled: enabled,
              onChanged: onChanged,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                prefixIcon: prefixIcon,
                suffixIcon: suffixIcon,
                errorMaxLines: 2,
                filled: true,
                fillColor: AppTheme.surfaceGlassDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppTheme.surfaceGlassBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppTheme.surfaceGlassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.accentTeal, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.errorCoral),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// An icon button with glassmorphism styling
class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? iconColor;
  final bool isAccent;

  const GlassIconButton({
    Key? key,
    required this.icon,
    this.onPressed,
    this.size = 48,
    this.iconColor,
    this.isAccent = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Material(
          color: isAccent
              ? AppTheme.accentTeal.withOpacity(0.2)
              : AppTheme.surfaceGlassDark,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(size / 2),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isAccent
                      ? AppTheme.accentTeal.withOpacity(0.5)
                      : AppTheme.surfaceGlassBorder,
                  width: 1.5,
                ),
              ),
              child: Icon(
                icon,
                color: iconColor ?? (isAccent ? AppTheme.accentTeal : AppTheme.textSecondary),
                size: size * 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A chip with glassmorphism styling
class GlassChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color? selectedColor;

  const GlassChip({
    Key? key,
    required this.label,
    this.icon,
    this.isSelected = false,
    this.onTap,
    this.selectedColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = selectedColor ?? AppTheme.accentTeal;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : AppTheme.surfaceGlassDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppTheme.surfaceGlassBorder,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? color : AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A stat card with glassmorphism styling and accent color
class GlassStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? accentColor;
  final String? subtitle;
  final VoidCallback? onTap;

  const GlassStatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    this.accentColor,
    this.subtitle,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppTheme.accentTeal;

    return GlassContainer(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A navigation bar with glassmorphism styling
class GlassNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<GlassNavigationItem> items;

  const GlassNavigationBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.primaryNavy.withOpacity(0.8),
            border: Border(
              top: BorderSide(
                color: AppTheme.surfaceGlassBorder,
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                items.length,
                (index) => _buildItem(items[index], index),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(GlassNavigationItem item, int index) {
    final isSelected = index == currentIndex;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentTeal.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? item.activeIcon : item.icon,
              color: isSelected ? AppTheme.accentTeal : AppTheme.textMuted,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppTheme.accentTeal : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Navigation item for GlassNavigationBar
class GlassNavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const GlassNavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// A list tile with glassmorphism styling
class GlassListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  const GlassListTile({
    Key? key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      onTap: onTap,
      padding: padding ?? const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 4),
      borderRadius: 16,
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// A badge with accent styling
class GlassBadge extends StatelessWidget {
  final String text;
  final Color? color;

  const GlassBadge({
    Key? key,
    required this.text,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final badgeColor = color ?? AppTheme.accentTeal;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: badgeColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: badgeColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// A progress indicator with glassmorphism styling
class GlassProgressBar extends StatelessWidget {
  final double value;
  final double height;
  final Color? color;
  final Color? backgroundColor;

  const GlassProgressBar({
    Key? key,
    required this.value,
    this.height = 8,
    this.color,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.surfaceGlassDark,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color ?? AppTheme.accentTeal,
                (color ?? AppTheme.accentTeal).withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(height / 2),
            boxShadow: [
              BoxShadow(
                color: (color ?? AppTheme.accentTeal).withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
