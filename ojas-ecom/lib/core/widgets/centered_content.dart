import 'package:flutter/material.dart';

class CenteredContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final double horizontalPadding;

  const CenteredContent({
    super.key,
    required this.child,
    this.maxWidth = 1350,
    this.horizontalPadding = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: child,
        ),
      ),
    );
  }
}
