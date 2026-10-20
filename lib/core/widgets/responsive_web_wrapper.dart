import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Custom ScrollBehavior enabling smooth mouse drag & wheel scrolling on Web and Desktop
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

/// A responsive wrapper that gracefully centers the app on large desktop/laptop browsers
/// while maintaining 100% full-screen responsive flow on mobile devices.
class ResponsiveWebWrapper extends StatelessWidget {
  final Widget child;
  final double maxWebWidth;

  const ResponsiveWebWrapper({
    super.key,
    required this.child,
    this.maxWebWidth = 600.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // If on small screen / mobile viewport, render full screen directly
        if (constraints.maxWidth <= maxWebWidth) {
          return child;
        }

        // On larger desktop/laptop displays, center with a sleek frame and subtle shadow
        return Container(
          color: const Color(0xFFEDF2EC), // Earthy soft background on outer desktop canvas
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWebWidth,
                maxHeight: constraints.maxHeight,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x18000000),
                      blurRadius: 24,
                      spreadRadius: 4,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRect(
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
