import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// A robust widget for rendering external Lottie animations (JSON files downloaded
/// from LottieFiles or custom animation sources) with graceful fallbacks.
class ExternalAnimationView extends StatelessWidget {
  final String? assetPath;
  final String? url;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final bool repeat;
  final Widget? fallbackWidget;

  const ExternalAnimationView({
    super.key,
    this.assetPath,
    this.url,
    this.width,
    this.height,
    this.fit,
    this.repeat = true,
    this.fallbackWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (assetPath != null && assetPath!.isNotEmpty) {
      return Lottie.asset(
        assetPath!,
        width: width,
        height: height,
        fit: fit ?? BoxFit.contain,
        repeat: repeat,
        errorBuilder: (context, error, stackTrace) {
          return fallbackWidget ??
              SizedBox(
                width: width ?? 60,
                height: height ?? 60,
                child: const Center(
                  child: Icon(Icons.animation, color: Colors.grey, size: 32),
                ),
              );
        },
      );
    } else if (url != null && url!.isNotEmpty) {
      return Lottie.network(
        url!,
        width: width,
        height: height,
        fit: fit ?? BoxFit.contain,
        repeat: repeat,
        errorBuilder: (context, error, stackTrace) {
          return fallbackWidget ??
              SizedBox(
                width: width ?? 60,
                height: height ?? 60,
                child: const Center(
                  child: Icon(Icons.animation, color: Colors.grey, size: 32),
                ),
              );
        },
      );
    }

    return fallbackWidget ??
        SizedBox(
          width: width ?? 60,
          height: height ?? 60,
          child: const Center(
            child: Icon(Icons.animation, color: Colors.grey, size: 32),
          ),
        );
  }
}
