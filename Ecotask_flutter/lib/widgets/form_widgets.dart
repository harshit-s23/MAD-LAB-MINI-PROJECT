import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';

/// Field label above an input (`text-sm font-medium` on auth pages,
/// uppercase `text-xs font-semibold` in the task form).
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.uppercase = false});

  final String text;
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(uppercase ? text.toUpperCase() : text,
          style: uppercase ? AppText.fieldLabel : AppText.label),
    );
  }
}

/// Labelled text input used on every form.
class LabeledTextField extends StatelessWidget {
  const LabeledTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.obscure = false,
    this.validator,
    this.textInputAction,
    this.onSubmitted,
    this.autofillHints,
    this.maxLines = 1,
    this.uppercaseLabel = false,
    this.dense = false,
    this.fieldKey,
    this.onChanged,
    this.autocorrect = true,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscure;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final int maxLines;
  final bool uppercaseLabel;
  final bool dense;
  final Key? fieldKey;
  final ValueChanged<String>? onChanged;
  final bool autocorrect;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label, uppercase: uppercaseLabel),
        TextFormField(
          key: fieldKey,
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          validator: validator,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          onChanged: onChanged,
          autofillHints: autofillHints,
          maxLines: obscure ? 1 : maxLines,
          autocorrect: autocorrect && !obscure,
          enableSuggestions: !obscure,
          textCapitalization: textCapitalization,
          style: AppText.input,
          cursorColor: AppColors.forest600,
          decoration: AppTheme.inputDecoration(
            hint: hint,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16, vertical: dense ? 10 : 12),
          ),
        ),
      ],
    );
  }
}

/// Dropdown styled like the original `<select>` controls.
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.dense = true,
  });

  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: AppTheme.inputDecoration(
        contentPadding:
            EdgeInsets.symmetric(horizontal: 16, vertical: dense ? 2 : 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          isDense: false,
          borderRadius: BorderRadius.circular(12),
          dropdownColor: Colors.white,
          style: AppText.input,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.sage500),
        ),
      ),
    );
  }
}

/// Tappable date field (replaces `<input type="date">`).
class DateFieldBox extends StatelessWidget {
  const DateFieldBox({
    super.key,
    required this.value,
    required this.onTap,
    this.placeholder = 'Select date',
    this.onClear,
    this.dense = true,
  });

  final String value;
  final VoidCallback onTap;
  final String placeholder;
  final VoidCallback? onClear;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final empty = value.isEmpty;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: InputDecorator(
        decoration: AppTheme.inputDecoration(
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16, vertical: dense ? 12 : 14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(empty ? placeholder : value,
                  style: empty ? AppText.hint : AppText.input,
                  overflow: TextOverflow.ellipsis),
            ),
            if (!empty && onClear != null)
              GestureDetector(
                onTap: onClear,
                child: const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(Icons.close, size: 16, color: AppColors.sage500),
                ),
              )
            else
              const Icon(Icons.calendar_today_outlined,
                  size: 16, color: AppColors.sage500),
          ],
        ),
      ),
    );
  }
}
