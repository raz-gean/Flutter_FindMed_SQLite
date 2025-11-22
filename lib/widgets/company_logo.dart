import 'package:flutter/material.dart';

/// CompanyLogo renders a circular or rounded logo for a pharmacy chain.
/// Falls back to an icon if the asset isn't mapped.
class CompanyLogo extends StatelessWidget {
  final String companyName;
  final double size;
  final double borderRadius; // if > 0 and not circle, apply radius
  final bool circular;
  const CompanyLogo({
    super.key,
    required this.companyName,
    this.size = 44,
    this.borderRadius = 0,
    this.circular = false, // default to rounded rectangle per new design
  });

  static const Map<String, String> _logoAssets = {
    'Mercury Drug': 'assets/imgs/Mercury_Logo.png',
    'Rose Pharmacy': 'assets/imgs/Rose_Logo.png',
    'Generika Drugstore': 'assets/imgs/Generika_Logo.png',
    'The Generics Pharmacy': 'assets/imgs/TGP_Logo.jpg',
  };

  @override
  Widget build(BuildContext context) {
    final path = _logoAssets[companyName];
    if (path == null) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: Colors.blue.withValues(alpha: 0.08),
        child: const Icon(Icons.local_pharmacy, color: Colors.blue),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: circular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circular
            ? null
            : BorderRadius.circular(
                borderRadius > 0 ? borderRadius : size * 0.15,
              ),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(2),
      child: Image.asset(path, fit: BoxFit.contain),
    );
  }
}
