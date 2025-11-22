import 'package:flutter/material.dart';

/// Reusable circular FindMed logo widget.
/// Wraps the logo image in a circular container with optional Hero animation.
class FindMedLogo extends StatelessWidget {
  final double size;
  final bool hero;
  final EdgeInsetsGeometry? margin;
  final Color? borderColor;
  final Color? backgroundColor;
  final bool circular; // allow switching between circle and rounded rectangle
  final double? borderRadius; // custom radius if not circular
  const FindMedLogo({
    super.key,
    this.size = 40,
    this.hero = true,
    this.margin,
    this.borderColor,
    this.backgroundColor,
    this.circular = false,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? size * 0.15; // 15% of size if unspecified
    Widget logo = Container(
      margin: margin,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: circular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circular ? null : BorderRadius.circular(radius),
        color: backgroundColor ?? Colors.white,
        border: Border.all(
          color: borderColor ?? Colors.grey.shade300,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(2),
      child: Image.asset('assets/imgs/findmed_logo.png', fit: BoxFit.contain),
    );

    if (hero) {
      return Hero(tag: 'appLogo', child: logo);
    }
    return logo;
  }
}
