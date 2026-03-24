import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mytiny_diary/theme/sanctuary_theme.dart';

/// A neumorphic "extruded" container – the core building block.
///
/// Looks like a piece of the surface pushed toward the user.
class NeuCard extends StatelessWidget {
  const NeuCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.color,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? SanctuaryRadius.lg;
    final bg = color ?? SanctuaryColors.surfaceContainerLow;

    Widget card = Container(
      margin: margin ?? EdgeInsets.zero,
      padding: padding ?? const EdgeInsets.all(SanctuarySpacing.xl),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: SanctuaryShadows.extruded(),
      ),
      child: child,
    );

    if (onTap != null) {
      card = GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}

/// A recessed "well" – used for input areas and active nav items.
class NeuWell extends StatelessWidget {
  const NeuWell({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? SanctuaryRadius.lg;
    return Container(
      padding: padding ?? const EdgeInsets.all(SanctuarySpacing.xl),
      decoration: BoxDecoration(
        color: color ?? SanctuaryColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: SanctuaryShadows.recessed(),
      ),
      child: child,
    );
  }
}

/// A neumorphic button with press animation.
class NeuButton extends StatefulWidget {
  const NeuButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color,
    this.padding,
    this.borderRadius,
    this.enabled = true,
    this.expanded = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final bool enabled;
  final bool expanded;

  @override
  State<NeuButton> createState() => _NeuButtonState();
}

class _NeuButtonState extends State<NeuButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? SanctuaryRadius.xl;
    final bg = widget.color ?? SanctuaryColors.primaryContainer;
    final shadows = (_pressed && widget.enabled)
        ? SanctuaryShadows.recessed()
        : SanctuaryShadows.extruded();

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      padding:
          widget.padding ??
          const EdgeInsets.symmetric(
            horizontal: SanctuarySpacing.xl,
            vertical: SanctuarySpacing.lg,
          ),
      decoration: BoxDecoration(
        color: widget.enabled ? bg : bg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: widget.enabled ? shadows : [],
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(
          color: widget.enabled
              ? SanctuaryColors.onPrimaryContainer
              : SanctuaryColors.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        child: IconTheme.merge(
          data: IconThemeData(
            color: widget.enabled
                ? SanctuaryColors.onPrimaryContainer
                : SanctuaryColors.onSurfaceVariant,
          ),
          child: widget.child,
        ),
      ),
    );

    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: widget.enabled
          ? () => setState(() => _pressed = false)
          : null,
      onTap: widget.enabled ? widget.onPressed : null,
      child: widget.expanded
          ? SizedBox(width: double.infinity, child: content)
          : content,
    );
  }
}

/// Glassmorphic FAB matching the design system.
class GlassFab extends StatelessWidget {
  const GlassFab({super.key, required this.onPressed, this.icon});

  final VoidCallback onPressed;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(SanctuaryRadius.xxl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: SanctuaryColors.surfaceTint.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(SanctuaryRadius.xxl),
              border: Border.all(
                color: SanctuaryColors.outlineVariant.withValues(alpha: 0.12),
              ),
              boxShadow: SanctuaryShadows.extruded(),
            ),
            child: Center(
              child:
                  icon ??
                  const Icon(
                    Icons.add_rounded,
                    color: SanctuaryColors.primary,
                    size: 28,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Section label used throughout detail / create screens.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SanctuarySpacing.sm),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: SanctuaryColors.onSurfaceVariant,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
