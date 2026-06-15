import 'package:flutter/material.dart';
import 'package:ojas_user/core/widgets/ojas_layout.dart';

class ShellScreen extends StatelessWidget {
  final Widget child;
  final String activeTitle;
  const ShellScreen({super.key, required this.child, this.activeTitle = 'HOME'});

  @override
  Widget build(BuildContext context) {
    return OjasLayout(activeTitle: activeTitle, child: child);
  }
}

