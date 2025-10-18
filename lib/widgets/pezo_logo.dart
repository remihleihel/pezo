import 'package:flutter/material.dart';

class PezoLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final Color? color;
  final BoxFit fit;

  const PezoLogo({
    super.key,
    this.width,
    this.height,
    this.color,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/Pezo_logo.png',
      width: width,
      height: height,
      fit: fit,
      color: color,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to text if image fails to load
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              'Pezo',
              style: TextStyle(
                color: Colors.white,
                fontSize: (height ?? 40) * 0.4,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}

class PezoLogoWithText extends StatelessWidget {
  final double? logoSize;
  final double? textSize;
  final Color? textColor;
  final bool showSubtitle;

  const PezoLogoWithText({
    super.key,
    this.logoSize = 60,
    this.textSize = 24,
    this.textColor,
    this.showSubtitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveTextColor = textColor ?? theme.textTheme.headlineSmall?.color;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PezoLogo(
          width: logoSize,
          height: logoSize,
        ),
        const SizedBox(height: 8),
        Text(
          'Pezo',
          style: TextStyle(
            fontSize: textSize,
            fontWeight: FontWeight.bold,
            color: effectiveTextColor,
          ),
        ),
        if (showSubtitle) ...[
          const SizedBox(height: 2),
          Text(
            'Never run out of Pesos',
            style: TextStyle(
              fontSize: (textSize ?? 24) * 0.5,
              color: effectiveTextColor?.withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}
