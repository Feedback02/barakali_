import 'package:flutter/material.dart';
import 'package:barakali/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:barakali/core/utils/format.dart';
import 'package:barakali/core/widgets/barakali_card.dart';
import 'package:barakali/core/widgets/barakali_dialog.dart';
import 'package:barakali/core/widgets/barakali_image.dart';
import 'package:barakali/core/widgets/language_menu_button.dart';
import 'package:barakali/features/auth/providers/auth_providers.dart';
import '../domain/models/offer.dart';
import '../providers/merchant_providers.dart';
import '../providers/offer_providers.dart';

class MerchantDashboardScreen extends ConsumerWidget {
  const MerchantDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final merchantAsync = ref.watch(myMerchantProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.merchantDashboardTitle),
        actions: [
          if (merchantAsync.value?.isApproved ?? false)
            IconButton(
              icon: const Icon(Icons.receipt_long_rounded),
              tooltip: l10n.navOrders,
              onPressed: () => context.push('/merchant/orders'),
            ),
          IconButton(
            icon: const Icon(Icons.notifications_rounded),
            tooltip: l10n.notificationSettingsTitle,
            onPressed: () => context.push('/notifications/settings'),
          ),
          const LanguageMenuButton(),
          IconButton(
            icon: Icon(
              Icons.logout_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            tooltip: l10n.authSignOut,
            onPressed: () => ref.read(authStateProvider.notifier).signOut(),
          ),
        ],
      ),
      body: merchantAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.authErrorGeneric)),
        data: (merchant) {
          if (merchant == null) {
            return Center(child: Text(l10n.authErrorGeneric));
          }
          return merchant.isApproved
              ? const _ApprovedDashboard()
              : _PendingApproval(businessName: merchant.businessName);
        },
      ),
    );
  }
}

class _PendingApproval extends StatelessWidget {
  const _PendingApproval({required this.businessName});

  final String businessName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hourglass_top_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 16),
            Text(
              businessName,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.merchantPendingTitle,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.merchantPendingBody,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Dashboard list filters. `past` = terminal (expired/cancelled by
/// effectiveStatus); `active` = everything else (draft/active/sold-out).
enum _OfferFilter { active, past, all }

bool _matchesFilter(Offer offer, _OfferFilter filter) {
  final status = offer.effectiveStatus;
  final isPast =
      status == OfferStatus.expired || status == OfferStatus.cancelled;
  return switch (filter) {
    _OfferFilter.all => true,
    _OfferFilter.active => !isPast,
    _OfferFilter.past => isPast,
  };
}

class _ApprovedDashboard extends ConsumerStatefulWidget {
  const _ApprovedDashboard();

  @override
  ConsumerState<_ApprovedDashboard> createState() => _ApprovedDashboardState();
}

class _ApprovedDashboardState extends ConsumerState<_ApprovedDashboard> {
  // Default hides terminal (expired/cancelled) offers so they don't clutter.
  _OfferFilter _filter = _OfferFilter.active;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final offersAsync = ref.watch(myOffersProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.push('/merchant/create-offer'),
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.merchantCreateOffer),
            ),
          ),
        ),
        Expanded(
          child: offersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(child: Text(l10n.authErrorGeneric)),
            data: (offers) {
              if (offers.isEmpty) return const _OffersEmpty();
              final filtered = offers
                  .where((o) => _matchesFilter(o, _filter))
                  .toList();
              return Column(
                children: [
                  _OfferFilterBar(
                    selected: _filter,
                    onSelected: (f) => setState(() => _filter = f),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => ref.refresh(myOffersProvider.future),
                      child: filtered.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    32,
                                    48,
                                    32,
                                    32,
                                  ),
                                  child: Text(
                                    l10n.offerFilterEmpty,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.6),
                                        ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (_, i) =>
                                  _OfferCard(offer: filtered[i]),
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _OfferFilterBar extends StatelessWidget {
  const _OfferFilterBar({required this.selected, required this.onSelected});

  final _OfferFilter selected;
  final ValueChanged<_OfferFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = <_OfferFilter, String>{
      _OfferFilter.active: l10n.offerFilterActive,
      _OfferFilter.past: l10n.offerFilterPast,
      _OfferFilter.all: l10n.offerFilterAll,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Wrap(
          spacing: 8,
          children: [
            for (final f in _OfferFilter.values)
              ChoiceChip(
                label: Text(labels[f]!),
                selected: selected == f,
                onSelected: (_) => onSelected(f),
              ),
          ],
        ),
      ),
    );
  }
}

class _OffersEmpty extends StatelessWidget {
  const _OffersEmpty();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.offersEmptyTitle,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.offersEmptyBody,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

enum _OfferAction { edit, publish, deactivate, cancel, repeat, delete }

class _OfferCard extends ConsumerWidget {
  const _OfferCard({required this.offer});

  final Offer offer;

  // Uses effectiveStatus so an active offer whose pickup window has already
  // passed (but the 5-min cron hasn't flipped yet) is treated as terminal.
  bool get _isEditable =>
      offer.effectiveStatus == OfferStatus.draft ||
      offer.effectiveStatus == OfferStatus.active;

  List<PopupMenuEntry<_OfferAction>> _menuItems(AppLocalizations l10n) {
    final status = offer.effectiveStatus;
    return [
      if (_isEditable)
        PopupMenuItem(
          value: _OfferAction.edit,
          child: Text(l10n.offerActionEdit),
        ),
      if (status == OfferStatus.draft)
        PopupMenuItem(
          value: _OfferAction.publish,
          child: Text(l10n.offerActionPublish),
        ),
      if (status == OfferStatus.active) ...[
        PopupMenuItem(
          value: _OfferAction.deactivate,
          child: Text(l10n.offerActionDeactivate),
        ),
        PopupMenuItem(
          value: _OfferAction.cancel,
          child: Text(l10n.offerActionCancel),
        ),
      ],
      PopupMenuItem(
        value: _OfferAction.repeat,
        child: Text(l10n.offerActionRepeat),
      ),
      PopupMenuItem(
        value: _OfferAction.delete,
        child: Text(l10n.offerActionDelete),
      ),
    ];
  }

  Future<void> _handle(
    BuildContext context,
    WidgetRef ref,
    _OfferAction action,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    switch (action) {
      case _OfferAction.edit:
        context.push('/merchant/edit-offer', extra: offer);
      case _OfferAction.repeat:
        context.push('/merchant/create-offer', extra: offer);
      case _OfferAction.publish:
        await ref
            .read(manageOffersProvider.notifier)
            .setStatus(offer.id, OfferStatus.active);
        if (!context.mounted) return;
        _report(context, ref, messenger, l10n.offerStatusUpdated);
      case _OfferAction.deactivate:
        await ref
            .read(manageOffersProvider.notifier)
            .setStatus(offer.id, OfferStatus.draft);
        if (!context.mounted) return;
        _report(context, ref, messenger, l10n.offerStatusUpdated);
      case _OfferAction.cancel:
        final ok = await BarakaliDialog.confirm(
          context,
          title: l10n.offerCancelConfirmTitle,
          body: l10n.offerCancelConfirmBody,
          confirmLabel: l10n.offerActionCancel,
          cancelLabel: l10n.dialogCancel,
          destructive: true,
        );
        if (!ok || !context.mounted) return;
        await ref
            .read(manageOffersProvider.notifier)
            .setStatus(offer.id, OfferStatus.cancelled);
        if (!context.mounted) return;
        _report(context, ref, messenger, l10n.offerStatusUpdated);
      case _OfferAction.delete:
        final ok = await BarakaliDialog.confirm(
          context,
          title: l10n.offerDeleteConfirmTitle,
          body: l10n.offerDeleteConfirmBody,
          confirmLabel: l10n.offerActionDelete,
          cancelLabel: l10n.dialogCancel,
          destructive: true,
        );
        if (!ok || !context.mounted) return;
        await ref.read(manageOffersProvider.notifier).delete(offer.id);
        if (!context.mounted) return;
        _report(context, ref, messenger, l10n.offerDeletedSuccess);
    }
  }

  void _report(
    BuildContext context,
    WidgetRef ref,
    ScaffoldMessengerState messenger,
    String success,
  ) {
    final l10n = AppLocalizations.of(context);
    final msg = ref.read(manageOffersProvider).hasError
        ? l10n.offerActionError
        : success;
    messenger.showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return BarakaliCard(
      onTap: _isEditable
          ? () => context.push('/merchant/edit-offer', extra: offer)
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BarakaliImage(url: offer.imageUrl, width: 64, height: 64),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.title,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      l10n.priceUzs(groupThousands(offer.discountedPrice)),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      groupThousands(offer.originalPrice),
                      style: theme.textTheme.bodySmall?.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _StatusBadge(status: offer.effectiveStatus),
                    const SizedBox(width: 8),
                    Text(
                      l10n.offerQuantityLeft(offer.quantityRemaining),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        formatPickupWindow(
                          context,
                          offer.pickupStart,
                          offer.pickupEnd,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<_OfferAction>(
            icon: const Icon(Icons.more_vert_rounded),
            itemBuilder: (_) => _menuItems(l10n),
            onSelected: (action) => _handle(context, ref, action),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final OfferStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final (label, color) = switch (status) {
      OfferStatus.draft => (l10n.offerStatusDraft, scheme.outline),
      OfferStatus.active => (l10n.offerStatusActive, scheme.primary),
      OfferStatus.soldOut => (l10n.offerStatusSoldOut, scheme.secondary),
      OfferStatus.expired => (l10n.offerStatusExpired, scheme.outline),
      OfferStatus.cancelled => (l10n.offerStatusCancelled, scheme.error),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
