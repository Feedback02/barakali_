import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:barakali/core/l10n/app_localizations.dart';
import 'package:barakali/core/models/dietary.dart';
import 'package:barakali/core/theme/brand_colors.dart';
import 'package:barakali/core/utils/contrast.dart';
import 'package:barakali/core/utils/format.dart';
import 'package:barakali/core/widgets/barakali_card.dart';
import 'package:barakali/core/widgets/barakali_empty_state.dart';
import 'package:barakali/core/widgets/barakali_image.dart';
import 'package:barakali/core/widgets/barakali_price_tag.dart';
import 'package:barakali/features/auth/domain/models/user_profile.dart';
import 'package:barakali/features/auth/providers/auth_providers.dart';
import 'package:barakali/features/merchant/domain/models/offer.dart';
import '../domain/models/offer_with_merchant.dart';
import '../providers/browse_providers.dart';
import '../providers/location_providers.dart';
import 'offer_labels.dart';
import 'widgets/price_marker.dart';

// Map pins always sit on Google's light map tiles, so their colors are fixed to
// the brand palette regardless of the app's light/dark theme (see the shared
// fills in contrast.dart). Selected pins use the terracotta accent, darkened for
// white text.

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  static const _clusterManagerId = ClusterManagerId('merchants');

  GoogleMapController? _controller;
  Set<Marker> _markers = {};
  String? _selectedMerchantId;

  // Rebuilding the marker bitmaps is async; this guards against redoing it
  // every frame. We only re-render when the merchant set or the selection
  // changes (camera moves don't touch markers).
  String _markerSignature = '';
  // Monotonic build id: a later schedule may finish before an earlier one (cache
  // hits resolve instantly), so a stale build's result is dropped.
  int _markerGen = 0;
  final Map<String, BitmapDescriptor> _bitmapCache = {};

  @override
  void initState() {
    super.initState();
    // Seed the shared dietary filter from the standing preference once (the Map
    // may be the first browse surface mounted). seedDietary dedupes with Home.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prefs = ref.read(currentUserProfileProvider).value?.dietaryOptions;
      if (prefs != null) {
        ref.read(browseFilterProvider.notifier).seedDietary(prefs);
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final offersAsync = ref.watch(browseOffersProvider);
    final dietary = ref.watch(browseFilterProvider).dietaryPrefs;
    final coords = ref.watch(userLocationProvider).value;

    ref.listen(currentUserProfileProvider, (_, next) {
      final prefs = next.value?.dietaryOptions;
      if (prefs != null) {
        ref.read(browseFilterProvider.notifier).seedDietary(prefs);
      }
    });

    final center = coords != null
        ? LatLng(coords.lat, coords.lng)
        : LatLng(tashkentCenter.lat, tashkentCenter.lng);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navMap)),
      body: offersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => BarakaliEmptyState(
          icon: Icons.error_outline_rounded,
          title: l10n.browseErrorTitle,
        ),
        data: (allOffers) {
          final offers = dietary.isEmpty
              ? allOffers
              : [
                  for (final o in allOffers)
                    if (offerSatisfiesDietary(
                      prefs: dietary,
                      offerTags: o.offer.dietaryOptions,
                      merchantIsHalal: o.merchant.isHalal,
                    ))
                      o,
                ];
          final byMerchant = _groupByMerchant(offers);
          if (byMerchant.isEmpty) {
            return BarakaliEmptyState(
              icon: Icons.map_outlined,
              title: l10n.browseEmptyTitle,
              message: l10n.browseEmptyBody,
            );
          }

          // Schedule an async marker rebuild when inputs change. Deferred to a
          // post-frame callback so the bitmap build + setState never run during
          // this build (the signature is set synchronously to avoid rescheduling
          // the same rebuild on the frames before it completes).
          _maybeScheduleMarkers(byMerchant);

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(target: center, zoom: 12),
                markers: _markers,
                clusterManagers: {
                  ClusterManager(
                    clusterManagerId: _clusterManagerId,
                    onClusterTap: _onClusterTap,
                  ),
                },
                myLocationEnabled: coords != null,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                onMapCreated: (c) => _controller = c,
                onTap: (_) => _clearSelection(),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: _CountChip(count: byMerchant.length),
              ),
            ],
          );
        },
      ),
      floatingActionButton: offersAsync.hasValue
          ? FloatingActionButton.small(
              heroTag: 'map_my_location',
              tooltip: l10n.mapMyLocation,
              onPressed: _goToMyLocation,
              child: const Icon(Icons.my_location_rounded),
            )
          : null,
    );
  }

  /// Groups offers by merchant, keeping only merchants with coordinates (a
  /// merchant without lat/lng can't be placed on the map).
  Map<String, List<OfferWithMerchant>> _groupByMerchant(
    List<OfferWithMerchant> offers,
  ) {
    final byMerchant = <String, List<OfferWithMerchant>>{};
    for (final o in offers) {
      if (o.merchant.latitude == null || o.merchant.longitude == null) continue;
      byMerchant.putIfAbsent(o.offer.merchantId, () => []).add(o);
    }
    return byMerchant;
  }

  /// The lowest discounted price across a merchant's offers, the figure shown
  /// on its pin (the cheapest bag is the strongest hook).
  int _lowestPrice(List<OfferWithMerchant> offers) => offers
      .map((o) => o.offer.discountedPrice)
      .reduce((a, b) => a < b ? a : b);

  void _maybeScheduleMarkers(Map<String, List<OfferWithMerchant>> byMerchant) {
    // Read dpr now (during build); the async work runs after the frame. Marker
    // colors are theme-independent (see _markerBrand), so the theme isn't folded
    // into the signature.
    final scale = MediaQuery.of(context).devicePixelRatio;

    final signature = [
      for (final id in byMerchant.keys) '$id:${_lowestPrice(byMerchant[id]!)}',
      'sel=$_selectedMerchantId',
      // Fold in the DPR so a density shift re-renders instead of keeping stale
      // pins.
      'dpr=$scale',
    ].join('|');
    if (signature == _markerSignature) return;
    _markerSignature = signature;

    final gen = ++_markerGen;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _buildMarkers(byMerchant, scale, gen);
    });
  }

  Future<void> _buildMarkers(
    Map<String, List<OfferWithMerchant>> byMerchant,
    double scale,
    int gen,
  ) async {
    final markers = <Marker>{};
    for (final entry in byMerchant.entries) {
      final id = entry.key;
      final items = entry.value;
      final merchant = items.first.merchant;
      final selected = id == _selectedMerchantId;
      final label = groupThousands(_lowestPrice(items));
      final icon = merchantCategoryIcon(merchant.category);
      final key = '${icon.codePoint}|$label|$selected|$scale';

      final bitmap =
          _bitmapCache[key] ??
          await buildPriceMarker(
            label: label,
            icon: icon,
            background: selected
                ? darkenForWhiteText(kBrandTerracotta)
                : kBrandGreen,
            foreground: Colors.white,
            scale: scale,
          );
      _bitmapCache[key] = bitmap;

      markers.add(
        Marker(
          markerId: MarkerId(id),
          position: LatLng(merchant.latitude!, merchant.longitude!),
          icon: bitmap,
          clusterManagerId: _clusterManagerId,
          zIndexInt: selected ? 1 : 0,
          onTap: () => _onMarkerTap(id, items),
        ),
      );
    }

    // A newer build superseded this one (or the widget is gone) — drop the
    // stale result rather than clobbering the current markers.
    if (!mounted || gen != _markerGen) return;
    setState(() => _markers = markers);
  }

  void _onMarkerTap(String merchantId, List<OfferWithMerchant> offers) {
    setState(() => _selectedMerchantId = merchantId);
    _showMerchantSheet(offers);
  }

  void _clearSelection() {
    if (_selectedMerchantId == null) return;
    setState(() => _selectedMerchantId = null);
  }

  Future<void> _onClusterTap(Cluster cluster) async {
    final controller = _controller;
    if (controller == null) return;
    // Zoom to fit the cluster's members so they fan out into individual pins.
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(cluster.bounds, 64),
    );
  }

  Future<void> _goToMyLocation() async {
    final coords = ref.read(userLocationProvider).value;
    if (coords == null) {
      // Not granted/resolved yet, re-request rather than silently doing nothing.
      ref.invalidate(userLocationProvider);
      return;
    }
    await _controller?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(coords.lat, coords.lng), 14),
    );
  }

  void _showMerchantSheet(List<OfferWithMerchant> offers) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                offers.first.merchant.name,
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
            ),
            for (final item in offers) ...[
              _MapOfferTile(
                item: item,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.push('/offer/${item.offer.id}', extra: item);
                },
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    ).whenComplete(_clearSelection);
  }
}

/// A small floating chip showing how many merchants are on the map.
class _CountChip extends StatelessWidget {
  const _CountChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(20),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.storefront_rounded,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(l10n.mapPlacesCount(count), style: theme.textTheme.labelLarge),
          ],
        ),
      ),
    );
  }
}

class _MapOfferTile extends StatelessWidget {
  const _MapOfferTile({required this.item, required this.onTap});

  final OfferWithMerchant item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final offer = item.offer;
    return BarakaliCard(
      onTap: onTap,
      child: Row(
        children: [
          BarakaliImage(url: offer.imageUrl, width: 56, height: 56),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.title,
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                BarakaliPriceTag(
                  originalPrice: offer.originalPrice,
                  discountedPrice: offer.discountedPrice,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}
