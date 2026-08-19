/// Per-user notification toggles, mirroring the `notification_preferences` table.
/// Immutable; defaults match the DB column defaults so a missing row (the user
/// never saved preferences) reads as a sensible default rather than failing.
/// `marketing` defaults to `false` — it is the only opt-IN flag (GDPR Art.7).
class NotificationPreferences {
  const NotificationPreferences({
    this.newOfferFromFavorite = true,
    this.pickupReminder = true,
    this.orderUpdates = true,
    this.marketing = false,
    this.dailyMerchantReminder = true,
  });

  final bool newOfferFromFavorite;
  final bool pickupReminder;
  final bool orderUpdates;
  final bool marketing;
  final bool dailyMerchantReminder;

  NotificationPreferences copyWith({
    bool? newOfferFromFavorite,
    bool? pickupReminder,
    bool? orderUpdates,
    bool? marketing,
    bool? dailyMerchantReminder,
  }) => NotificationPreferences(
    newOfferFromFavorite: newOfferFromFavorite ?? this.newOfferFromFavorite,
    pickupReminder: pickupReminder ?? this.pickupReminder,
    orderUpdates: orderUpdates ?? this.orderUpdates,
    marketing: marketing ?? this.marketing,
    dailyMerchantReminder: dailyMerchantReminder ?? this.dailyMerchantReminder,
  );

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      NotificationPreferences(
        newOfferFromFavorite: json['new_offer_from_favorite'] as bool? ?? true,
        pickupReminder: json['pickup_reminder'] as bool? ?? true,
        orderUpdates: json['order_updates'] as bool? ?? true,
        marketing: json['marketing'] as bool? ?? false,
        dailyMerchantReminder: json['daily_merchant_reminder'] as bool? ?? true,
      );

  /// The mutable preference columns (NOT `user_id`, which the repository adds).
  Map<String, dynamic> toJson() => {
    'new_offer_from_favorite': newOfferFromFavorite,
    'pickup_reminder': pickupReminder,
    'order_updates': orderUpdates,
    'marketing': marketing,
    'daily_merchant_reminder': dailyMerchantReminder,
  };

  @override
  bool operator ==(Object other) =>
      other is NotificationPreferences &&
      other.newOfferFromFavorite == newOfferFromFavorite &&
      other.pickupReminder == pickupReminder &&
      other.orderUpdates == orderUpdates &&
      other.marketing == marketing &&
      other.dailyMerchantReminder == dailyMerchantReminder;

  @override
  int get hashCode => Object.hash(
    newOfferFromFavorite,
    pickupReminder,
    orderUpdates,
    marketing,
    dailyMerchantReminder,
  );
}
