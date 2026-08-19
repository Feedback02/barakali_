import 'package:flutter/material.dart';

class BarakaliButton extends StatelessWidget {
  const BarakaliButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  // Match the button's label color so the spinner stays legible
                  // on the primary fill in both light and dark themes.
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              )
            : Text(label),
      ),
    );
  }
}
