import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// Full-screen layout of the auth screens: the [form] at the top and a
/// [footer] pinned to the bottom edge.
///
/// The column is at least as tall as the screen, so on iPhone 17 everything
/// fits without scrolling and the footer sits at the bottom. On smaller
/// screens, with large Dynamic Type or with the keyboard open, the same
/// layout simply becomes scrollable instead of overflowing.
class AuthPage extends StatelessWidget {
  const AuthPage({super.key, required this.form, required this.footer});

  final List<Widget> form;
  final List<Widget> footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        // Tap on empty space hides the keyboard.
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints viewport) {
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screen,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: viewport.maxHeight),
                  // spaceBetween puts any spare height between form and
                  // footer, so the footer hugs the bottom of the screen.
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: form,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: footer,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
