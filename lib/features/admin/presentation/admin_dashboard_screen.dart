import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:barakali/core/l10n/app_localizations.dart';
import 'package:barakali/core/utils/format.dart';
import 'package:barakali/core/widgets/barakali_card.dart';
import 'package:barakali/core/widgets/language_menu_button.dart';
import 'package:barakali/features/auth/providers/auth_providers.dart';
import '../domain/models/platform_metrics.dart';
import '../providers/admin_providers.dart';
import 'admin_action.dart';
import 'admin_fee_dialog.dart';

/// The admin operator console home: live platform metrics + a section index.
/// Reachable only by role='admin' (router redirect); every privileged action
/// behind these tiles is independently gated by RLS + is_admin() server-side.
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh metrics each time the console is (re)opened.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.invalidate(platformMetricsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminDashboardTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_rounded),
            tooltip: l10n.notificationSettingsTitle,
            onPressed: () => context.push('/notifications/settings'),
          ),
          const LanguageMenuButton(),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: l10n.authSignOut,
            onPressed: () => ref.read(authStateProvider.notifier).signOut(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(platformMetricsProvider.future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            const _MetricsSection(),
            const SizedBox(height: 16),
            const _PlatformFeeCard(),
            const SizedBox(height: 16),
            _SectionTile(
              icon: Icons.storefront_rounded,
              color: scheme.primary,
              title: l10n.adminSectionMerchants,
              subtitle: l10n.adminSectionMerchantsSubtitle,
              onTap: () => context.push('/admin/merchants'),
            ),
            _SectionTile(
              icon: Icons.receipt_long_rounded,
              color: scheme.secondary,
              title: l10n.adminSectionOrders,
              subtitle: l10n.adminSectionOrdersSubtitle,
              onTap: () => context.push('/admin/orders'),
            ),
            _SectionTile(
              icon: Icons.support_agent_rounded,
              color: scheme.tertiary,
              title: l10n.adminSectionSupport,
              subtitle: l10n.adminSectionSupportSubtitle,
              onTap: () => context.push('/admin/support'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricsSection extends ConsumerWidget {
  const _MetricsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return ref
        .watch(platformMetricsProvider)
        .when(
          skipLoadingOnReload: true,
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              l10n.adminMetricsError,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
          data: (m) => _MetricsGrid(metrics: m),
        );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.metrics});

  final PlatformMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tiles = <(String, String)>[
      (l10n.adminMetricOrdersToday, '${metrics.ordersToday}'),
      (l10n.adminMetricOrdersWeek, '${metrics.ordersWeek}'),
      (l10n.adminMetricOrdersMonth, '${metrics.ordersMonth}'),
      (
        l10n.adminMetricRevenue,
        l10n.priceUzs(groupThousands(metrics.revenueTotal)),
      ),
      (
        l10n.adminMetricCommission,
        l10n.priceUzs(groupThousands(metrics.commissionTotal)),
      ),
      (l10n.adminMetricBagsSaved, '${metrics.bagsSaved}'),
      (l10n.adminMetricActiveMerchants, '${metrics.activeMerchants}'),
      (l10n.adminMetricActiveConsumers, '${metrics.activeConsumers}'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final width = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final (label, value) in tiles)
              SizedBox(
                width: width,
                child: _MetricCard(label: label, value: value),
              ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BarakaliCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// The platform default fee per bag, with an admin edit action. The per-merchant
/// override lives on the merchant sheet (admin merchants screen).
class _PlatformFeeCard extends ConsumerWidget {
  const _PlatformFeeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final feeAsync = ref.watch(platformBagFeeProvider);
    final busy = ref.watch(adminFeeProvider).isLoading;

    return BarakaliCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.adminFeeDefaultLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  feeAsync.when(
                    data: (fee) => l10n.priceUzs(groupThousands(fee)),
                    loading: () => '...',
                    error: (_, _) => '-',
                  ),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: busy || feeAsync.isLoading
                ? null
                : () => _edit(context, ref, feeAsync.value),
            child: Text(l10n.adminFeeEdit),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, int? current) async {
    final result = await showFeeDialog(
      context,
      initial: current,
      allowDefault: false,
    );
    final fee = result?.fee;
    if (fee == null || !context.mounted) return;
    await runAdminAction(
      context,
      action: () => ref.read(adminFeeProvider.notifier).setPlatformFee(fee),
      readError: () => ref.read(adminFeeProvider).error,
      successMessage: (l10n) => l10n.adminFeeUpdated,
      popOnSuccess: false,
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, color: color, size: 32),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
