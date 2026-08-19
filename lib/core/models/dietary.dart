import 'package:flutter/material.dart';

import 'package:barakali/core/l10n/app_localizations.dart';

/// Dietary attributes shared across offers (per-bag tags), merchants (halal),
/// and consumer standing preferences. Wire values match the DB CHECK
/// vocabularies: `offers.dietary_tags` and `profiles.dietary_prefs` (text[]),
/// and `merchants.is_halal` (bool) for [DietaryOption.halal].
enum DietaryOption {
  halal('halal', Icons.mosque_rounded),
  vegetarian('vegetarian', Icons.eco_rounded),
  vegan('vegan', Icons.spa_rounded),
  noPork('no_pork', Icons.no_food_rounded),
  noAlcohol('no_alcohol', Icons.no_drinks_rounded);

  const DietaryOption(this.wire, this.icon);

  /// The value stored in the DB text[] (or, for halal, the flag this maps to).
  final String wire;

  /// Icon used on badges/chips/toggles.
  final IconData icon;

  /// halal is a merchant-level attestation, not a per-offer tag.
  bool get isOfferTag => this != DietaryOption.halal;

  static DietaryOption? fromWire(String value) {
    for (final o in DietaryOption.values) {
      if (o.wire == value) return o;
    }
    return null;
  }

  /// The attributes a merchant can tag on an individual offer (all but halal).
  static List<DietaryOption> get offerTags =>
      DietaryOption.values.where((o) => o.isOfferTag).toList();

  /// Parse a raw wire list (e.g. `offers.dietary_tags`), dropping any unknown
  /// values so a newer server vocabulary never crashes an older client.
  static Set<DietaryOption> parse(Iterable<String> wire) =>
      wire.map(fromWire).whereType<DietaryOption>().toSet();
}

extension DietaryOptionL10n on DietaryOption {
  /// Localized short label (ru/uz/en) used on badges, chips, and toggles.
  String label(AppLocalizations l10n) => switch (this) {
    DietaryOption.halal => l10n.dietaryHalal,
    DietaryOption.vegetarian => l10n.dietaryVegetarian,
    DietaryOption.vegan => l10n.dietaryVegan,
    DietaryOption.noPork => l10n.dietaryNoPork,
    DietaryOption.noAlcohol => l10n.dietaryNoAlcohol,
  };
}

/// Whether an offer with [offerTags], from a merchant with [merchantIsHalal],
/// satisfies every required standing preference in [prefs]. Mirrors the SQL
/// predicate in the `enqueue_new_offer_from_favorite` trigger exactly. An empty
/// [prefs] set matches everything. Implications: vegan satisfies vegetarian,
/// and vegetarian/vegan satisfy no_pork.
bool offerSatisfiesDietary({
  required Set<DietaryOption> prefs,
  required Set<DietaryOption> offerTags,
  required bool merchantIsHalal,
}) {
  for (final pref in prefs) {
    final satisfied = switch (pref) {
      DietaryOption.halal => merchantIsHalal,
      DietaryOption.vegetarian =>
        offerTags.contains(DietaryOption.vegetarian) ||
            offerTags.contains(DietaryOption.vegan),
      DietaryOption.vegan => offerTags.contains(DietaryOption.vegan),
      DietaryOption.noPork =>
        offerTags.contains(DietaryOption.noPork) ||
            offerTags.contains(DietaryOption.vegetarian) ||
            offerTags.contains(DietaryOption.vegan),
      DietaryOption.noAlcohol => offerTags.contains(DietaryOption.noAlcohol),
    };
    if (!satisfied) return false;
  }
  return true;
}
