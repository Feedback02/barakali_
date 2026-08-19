import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BarakaliInput extends StatelessWidget {
  const BarakaliInput({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.validator,
    this.prefixText,
    this.prefixIcon,
    this.inputFormatters,
    this.enabled = true,
    this.autofocus = false,
    this.onChanged,
    this.errorText,
    this.textAlign = TextAlign.start,
    this.style,
    this.maxLength,
    this.maxLines = 1,
    this.showCounter = false,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final String? prefixText;
  final Widget? prefixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final TextAlign textAlign;
  final TextStyle? style;
  final int? maxLength;
  final int maxLines;

  /// Show the live "N/maxLength" counter. Off by default (the design system
  /// hides counters); opt in for long free-text fields with a [maxLength] cap.
  final bool showCounter;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      inputFormatters: inputFormatters,
      enabled: enabled,
      autofocus: autofocus,
      onChanged: onChanged,
      textAlign: textAlign,
      style: style,
      maxLength: maxLength,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        prefixIcon: prefixIcon,
        errorText: errorText,
        alignLabelWithHint: maxLines > 1,
        counterText: showCounter ? null : '',
      ),
    );
  }
}
