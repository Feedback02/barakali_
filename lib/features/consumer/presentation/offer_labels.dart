import 'package:flutter/material.dart';

import 'package:barakali/core/l10n/app_localizations.dart';
import 'package:barakali/features/merchant/domain/models/offer.dart';

/// Localized label for an offer category, shared across consumer screens.
String offerCategoryLabel(AppLocalizations l10n, OfferCategory category) =>
    switch (category) {
      OfferCategory.meal => l10n.offerCategoryMeal,
      OfferCategory.bakery => l10n.offerCategoryBakery,
      OfferCategory.grocery => l10n.offerCategoryGrocery,
      OfferCategory.mixed => l10n.offerCategoryMixed,
      OfferCategory.other => l10n.offerCategoryOther,
    };

/// Localized label for a stored merchant-category token (the business type,
/// distinct from an offer's food category). Falls back to the raw token for any
/// value outside the known set.
String merchantCategoryLabel(AppLocalizations l10n, String category) =>
    switch (category) {
      'restaurant' => l10n.merchantCategoryRestaurant,
      'cafe' => l10n.merchantCategoryCafe,
      'bakery' => l10n.merchantCategoryBakery,
      'supermarket' => l10n.merchantCategorySupermarket,
      'other' => l10n.merchantCategoryOther,
      _ => category,
    };

/// Icon for a stored merchant-category token, used on map pins and headers.
IconData merchantCategoryIcon(String category) => switch (category) {
  'restaurant' => Icons.restaurant_rounded,
  'cafe' => Icons.local_cafe_rounded,
  'bakery' => Icons.bakery_dining_rounded,
  'supermarket' => Icons.local_grocery_store_rounded,
  _ => Icons.storefront_rounded,
};
