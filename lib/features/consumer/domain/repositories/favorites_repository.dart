abstract class FavoritesRepository {
  /// The merchant ids the current consumer has favorited (RLS scopes this to
  /// their own rows).
  Future<Set<String>> fetchFavoriteMerchantIds();

  /// Follows [merchantId] for the current consumer. Idempotent (a duplicate is
  /// a no-op).
  Future<void> addFavorite(String merchantId);

  /// Unfollows [merchantId] for the current consumer.
  Future<void> removeFavorite(String merchantId);
}
