import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  const LoadingOverlay({super.key, required this.isLoading, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      child,
      if (isLoading)
        const Positioned.fill(
          child: ColoredBox(color: Color(0x66000000),
            child: Center(child: CircularProgressIndicator(color: AppColors.primary)))),
    ]);
  }
}
