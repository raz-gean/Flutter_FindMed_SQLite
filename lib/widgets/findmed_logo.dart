import 'package:flutter/material.dart';

/// Reusable circular FindMed logo widget.
/// Wraps the logo image in a circular container with optional Hero animation.
class FindMedLogo extends StatelessWidget {
  final double size;
  final bool hero;
  final EdgeInsetsGeometry? margin;
  final Color? borderColor;
  final Color? backgroundColor;
  const FindMedLogo({
    super.key,
    this.size = 40,
    this.hero = true,
    this.margin,
    this.borderColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget logo = Container(
      margin: margin,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? Colors.white.withValues(alpha: 0.08),
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset('assets/imgs/findmed_logo.png', fit: BoxFit.cover),
    );

    if (hero) {
      return Hero(tag: 'appLogo', child: logo);
    }
    return logo;
  }
}
