import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Primary green button (full width by default).
class EcoButton extends StatelessWidget {
  const EcoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.expand = true,
    this.padding,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool expand;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    var style = AppTheme.primaryButton;
    if (padding != null) {
      style = style.copyWith(padding: WidgetStatePropertyAll(padding));
    }
    final button =
        ElevatedButton(onPressed: onPressed, style: style, child: Text(label));
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Secondary outlined button.
class EcoOutlinedButton extends StatelessWidget {
  const EcoOutlinedButton(
      {super.key,
      required this.label,
      required this.onPressed,
      this.expand = true});

  final String label;
  final VoidCallback? onPressed;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton(onPressed: onPressed, child: Text(label));
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
