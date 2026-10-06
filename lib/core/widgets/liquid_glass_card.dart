import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class LiquidGlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.borderRadius = 28,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: padding ?? const EdgeInsets.all(16),
      shape: LiquidRoundedSuperellipse(borderRadius: borderRadius),
      quality: GlassQuality.minimal,
      child: child,
    );
  }
}
