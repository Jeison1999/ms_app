import 'package:flutter/material.dart';

class AnimatedLogoHeader extends StatelessWidget {
  final Animation<double> opacity;
  final Animation<double> scale;
  final Animation<double> slideOffset;
  final String imageUrl;

  const AnimatedLogoHeader({
    super.key,
    required this.opacity,
    required this.scale,
    required this.slideOffset,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, slideOffset.value),
      child: Opacity(
        opacity: opacity.value,
        child: Transform.scale(
          scale: scale.value,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 200,
                child: Image.network(imageUrl, fit: BoxFit.contain),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
