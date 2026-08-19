import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'barakali_empty_state.dart';

/// A pull-to-refresh list backed by an [AsyncValue], centralizing the
/// loading / error / empty scaffolding shared by the order lists.
///
/// - keeps the current list visible during a reload (`skipLoadingOnReload`), so
///   a focus/invalidate refresh doesn't flash a full-screen spinner;
/// - makes the error AND empty states **pull-to-refresh-able** (always
///   scrollable), so the slide gesture always works.
///
/// [builder] is only invoked for a non-empty list.
class AsyncRefreshList<T> extends StatelessWidget {
  const AsyncRefreshList({
    super.key,
    required this.async,
    required this.onRefresh,
    required this.builder,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.errorTitle,
    this.emptyMessage,
  });

  final AsyncValue<List<T>> async;
  final Future<void> Function() onRefresh;
  final Widget Function(BuildContext context, List<T> items) builder;
  final IconData emptyIcon;
  final String emptyTitle;
  final String errorTitle;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: async.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            _message(icon: Icons.error_outline_rounded, title: errorTitle),
        data: (items) => items.isEmpty
            ? _message(
                icon: emptyIcon,
                title: emptyTitle,
                message: emptyMessage,
              )
            : builder(context, items),
      ),
    );
  }

  // Centered empty/error state that still scrolls, so pull-to-refresh works.
  Widget _message({
    required IconData icon,
    required String title,
    String? message,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        BarakaliEmptyState(icon: icon, title: title, message: message),
      ],
    );
  }
}
