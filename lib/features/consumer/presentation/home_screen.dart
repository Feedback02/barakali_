import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:barakali/core/l10n/app_localizations.dart';
import 'package:barakali/core/models/dietary.dart';
import 'package:barakali/core/widgets/barakali_empty_state.dart';
import 'package:barakali/core/widgets/barakali_loading_skeleton.dart';
import 'package:barakali/features/auth/domain/models/user_profile.dart';
import 'package:barakali/features/auth/providers/auth_providers.dart';
import 'package:barakali/features/merchant/domain/models/offer.dart';
import '../providers/browse_providers.dart';
import '../providers/location_providers.dart';
import 'offer_labels.dart';
import 'widgets/offer_card.dart';

/// Distance-radius filter options (km), null = "any".
const _distanceOptions = <double?>[null, 1, 3, 5, 10];

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final offersAsync = ref.watch(filteredBrowseProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          // Filled heart = "your favorites collection" (a shortcut to the saved
          // list), distinct from the outline heart used on offer detail to
          // toggle favoriting a store.
          IconButton(
            tooltip: l10n.favoritesTitle,
            icon: const Icon(Icons.favorite_rounded),
            onPressed: () => context.push('/favorites'),
          ),
        ],
      ),
      body: offersAsync.when(
        loading: () => const BarakaliLoadingSkeleton(),
        error: (_, _) => RefreshIndicator(
          onRefresh: () => ref.refresh(browseOffersProvider.future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 80),
                child: BarakaliEmptyState(
                  icon: Icons.error_outline_rounded,
                  title: l10n.browseErrorTitle,
                  action: OutlinedButton(
                    onPressed: () => ref.invalidate(browseOffersProvider),
                    child: Text(l10n.browseRetry),
                  ),
                ),
              ),
            ],
          ),
        ),
        data: (items) => Column(
          children: [
            const _BrowseFilterHeader(),
            Expanded(child: _BrowseList(items: items)),
          ],
        ),
      ),
    );
  }
}

class _BrowseList extends ConsumerWidget {
  const _BrowseList({required this.items});

  final List<BrowseItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final filterActive = ref.watch(browseFilterProvider).isActive;

    if (items.isEmpty) {
      final empty = filterActive
          ? BarakaliEmptyState(
              icon: Icons.search_off_rounded,
              title: l10n.browseNoResults,
              action: OutlinedButton(
                onPressed: () =>
                    ref.read(browseFilterProvider.notifier).clear(),
                child: Text(l10n.browseClearFilters),
              ),
            )
          : BarakaliEmptyState(
              icon: Icons.storefront_outlined,
              title: l10n.browseEmptyTitle,
              message: l10n.browseEmptyBody,
              action: OutlinedButton.icon(
                onPressed: () => ref.invalidate(browseOffersProvider),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(l10n.browseRefresh),
              ),
            );
      // Always scrollable: keeps the empty list pull-to-refreshable AND lets the
      // content scroll instead of overflowing when the search keyboard shrinks
      // the viewport (a bare centered column overflowed by a few px otherwise).
      return RefreshIndicator(
        onRefresh: () => ref.refresh(browseOffersProvider.future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Padding(padding: const EdgeInsets.only(top: 80), child: empty),
          ],
        ),
      );
    }

    return Column(
      children: [
        _SortBar(count: items.length),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.refresh(browseOffersProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) => OfferCard(
                item: items[i].offer,
                distanceKm: items[i].distanceKm,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Result count + a sort entry point above the browse list.
class _SortBar extends ConsumerWidget {
  const _SortBar({required this.count});

  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final sort = ref.watch(browseSortProvider);
    final hasLocation = ref.watch(userLocationProvider).value != null;
    // "Nearest" degrades to soonest-pickup without a location (and the sheet
    // hides it then), so advertise the effective sort rather than a state the
    // user can't see or reselect.
    final effectiveSort = sort == BrowseSort.nearest && !hasLocation
        ? BrowseSort.endingSoon
        : sort;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
      child: Row(
        children: [
          Text(
            l10n.browseOffersCount(count),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const Spacer(),
          // Compact: shrink-wrap the tap target so the row hugs its content
          // instead of reserving a full 48px button height (which read as a
          // large empty gap above the list).
          TextButton.icon(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
            onPressed: () => _showSortSheet(context, ref),
            icon: const Icon(Icons.swap_vert_rounded, size: 18),
            label: Text(_sortLabel(l10n, effectiveSort)),
          ),
        ],
      ),
    );
  }
}

String _sortLabel(AppLocalizations l10n, BrowseSort sort) => switch (sort) {
  BrowseSort.nearest => l10n.browseSortNearest,
  BrowseSort.endingSoon => l10n.browseSortEndingSoon,
  BrowseSort.priceLow => l10n.browseSortPrice,
};

IconData _sortIcon(BrowseSort sort) => switch (sort) {
  BrowseSort.nearest => Icons.near_me_outlined,
  BrowseSort.endingSoon => Icons.schedule_rounded,
  BrowseSort.priceLow => Icons.sell_outlined,
};

Future<void> _showSortSheet(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  // "Nearest" only sorts meaningfully once a location is known; hide it
  // otherwise (mirrors the distance filter).
  final hasLocation = ref.read(userLocationProvider).value != null;
  final current = ref.read(browseSortProvider);
  final options = <BrowseSort>[
    if (hasLocation) BrowseSort.nearest,
    BrowseSort.endingSoon,
    BrowseSort.priceLow,
  ];

  await showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                l10n.browseSortSheetTitle,
                style: theme.textTheme.titleMedium,
              ),
            ),
            for (final option in options)
              ListTile(
                leading: Icon(_sortIcon(option)),
                title: Text(_sortLabel(l10n, option)),
                trailing: option == current
                    ? Icon(
                        Icons.check_rounded,
                        color: theme.colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  ref.read(browseSortProvider.notifier).set(option);
                  Navigator.of(sheetContext).pop();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

class _BrowseFilterHeader extends ConsumerStatefulWidget {
  const _BrowseFilterHeader();

  @override
  ConsumerState<_BrowseFilterHeader> createState() =>
      _BrowseFilterHeaderState();
}

class _BrowseFilterHeaderState extends ConsumerState<_BrowseFilterHeader> {
  @override
  void initState() {
    super.initState();
    // Seed the dietary chips from the consumer's standing preference once, on
    // first mount, in a post-frame callback (never mutating a provider during
    // build). If the profile is not loaded yet, the listen in build() catches
    // the first load; seedDietary dedupes either way.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prefs = ref.read(currentUserProfileProvider).value?.dietaryOptions;
      if (prefs != null) {
        ref.read(browseFilterProvider.notifier).seedDietary(prefs);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filter = ref.watch(browseFilterProvider);
    final notifier = ref.read(browseFilterProvider.notifier);
    final hasLocation = ref.watch(userLocationProvider).value != null;

    // Seed when the profile first resolves after this header is already mounted.
    ref.listen(currentUserProfileProvider, (_, next) {
      final prefs = next.value?.dietaryOptions;
      if (prefs != null) notifier.seedDietary(prefs);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: _SearchField(),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              FilterChip(
                label: Text(l10n.offerFilterAll),
                selected: filter.categories.isEmpty,
                onSelected: (_) => notifier.clearCategories(),
              ),
              for (final category in OfferCategory.values) ...[
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(offerCategoryLabel(l10n, category)),
                  selected: filter.categories.contains(category),
                  onSelected: (_) => notifier.toggleCategory(category),
                ),
              ],
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              for (final option in DietaryOption.values) ...[
                if (option != DietaryOption.values.first)
                  const SizedBox(width: 8),
                FilterChip(
                  avatar: Icon(option.icon, size: 18),
                  label: Text(option.label(l10n)),
                  selected: filter.dietaryPrefs.contains(option),
                  onSelected: (_) => notifier.toggleDietary(option),
                ),
              ],
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: hasLocation
              ? Row(
                  children: [
                    for (final km in _distanceOptions) ...[
                      if (km != _distanceOptions.first)
                        const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(
                          km == null
                              ? l10n.filterDistanceAny
                              : l10n.distanceKm(km.toStringAsFixed(0)),
                        ),
                        selected: filter.maxKm == km,
                        onSelected: (selected) =>
                            notifier.setMaxKm(selected ? km : null),
                      ),
                    ],
                  ],
                )
              // Location not granted yet — offer an explicit re-request rather
              // than silently hiding distance filtering.
              : ActionChip(
                  avatar: const Icon(Icons.my_location_rounded, size: 18),
                  label: Text(l10n.filterUseLocation),
                  onPressed: () => ref.invalidate(userLocationProvider),
                ),
        ),
      ],
    );
  }
}

class _SearchField extends ConsumerStatefulWidget {
  const _SearchField();

  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextField(
      controller: _controller,
      textInputAction: TextInputAction.search,
      onChanged: (query) {
        ref.read(browseFilterProvider.notifier).setQuery(query);
        setState(() {}); // toggle the clear button as text changes
      },
      decoration: InputDecoration(
        hintText: l10n.searchHint,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  _controller.clear();
                  ref.read(browseFilterProvider.notifier).setQuery('');
                  setState(() {});
                },
              ),
        isDense: true,
      ),
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
    );
  }
}
