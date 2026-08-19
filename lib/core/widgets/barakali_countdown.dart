import 'dart:async';

import 'package:flutter/material.dart';

import 'package:barakali/core/l10n/app_localizations.dart';

enum _CountdownPhase { upcoming, open, closed }

/// The terracotta urgency accent, kept legible (WCAG AA) as text/icon on the
/// countdown's tint/surface in both themes. In light mode the raw hue
/// (`#C45B3A`) is only ~4:1 on the off-white card and the 10% tint, so darken
/// it past 4.5:1. In dark mode `tertiary` is already the lightened `#E08763` on
/// a near-black surface, so darkening would push it toward the background;
/// lighten it instead.
Color _readableUrgent(Color terracotta, Brightness brightness) {
  final hsl = HSLColor.fromColor(terracotta);
  final lightness = brightness == Brightness.dark
      ? (hsl.lightness + 0.10).clamp(0.0, 0.80)
      : (hsl.lightness - 0.16).clamp(0.0, 1.0);
  return hsl.withLightness(lightness).toColor();
}

/// A live, ticking countdown to a pickup window. Before the window opens it
/// counts down to [start] ("Pickup starts in ..."); while open it counts down to
/// [end] ("Pickup closes in ...") and turns urgent (terracotta) in the last
/// 30 min; once past [end] it shows a static "window closed" line.
///
/// [compact] renders an inline icon+text row (for list cards); otherwise a
/// tinted full-width banner (for the order/pickup screen).
class BarakaliCountdown extends StatefulWidget {
  const BarakaliCountdown({
    super.key,
    required this.start,
    required this.end,
    this.compact = false,
  });

  final DateTime start;
  final DateTime end;
  final bool compact;

  @override
  State<BarakaliCountdown> createState() => _BarakaliCountdownState();
}

class _BarakaliCountdownState extends State<BarakaliCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // A 1s tick keeps the minute label fresh and lets the final minute show
    // seconds. It only rebuilds this leaf widget; it self-cancels on unmount.
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final now = DateTime.now();
    final start = widget.start.toLocal();
    final end = widget.end.toLocal();

    final (phase, target) = now.isBefore(start)
        ? (_CountdownPhase.upcoming, start)
        : now.isBefore(end)
        ? (_CountdownPhase.open, end)
        : (_CountdownPhase.closed, end);

    final remaining = target.difference(now);
    final urgent =
        phase == _CountdownPhase.open &&
        remaining <= const Duration(minutes: 30);
    final color = switch (phase) {
      _CountdownPhase.closed => theme.colorScheme.onSurface.withValues(
        alpha: 0.6,
      ),
      _ when urgent => _readableUrgent(
        theme.colorScheme.tertiary,
        theme.brightness,
      ),
      _ => theme.colorScheme.primary,
    };

    final label = switch (phase) {
      _CountdownPhase.upcoming => l10n.pickupCountdownStartsIn(
        _formatDuration(l10n, remaining),
      ),
      _CountdownPhase.open => l10n.pickupCountdownClosesIn(
        _formatDuration(l10n, remaining),
      ),
      _CountdownPhase.closed => l10n.pickupCountdownClosed,
    };
    final icon = phase == _CountdownPhase.closed
        ? Icons.timer_off_outlined
        : Icons.timer_outlined;

    if (widget.compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(AppLocalizations l10n, Duration d) {
    if (d.isNegative) d = Duration.zero;
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    if (days >= 1) return l10n.countdownDaysHours(days, hours);
    if (hours >= 1) return l10n.countdownHoursMinutes(hours, minutes);
    if (minutes >= 1) return l10n.countdownMinutes(minutes);
    return l10n.countdownSeconds(seconds);
  }
}
