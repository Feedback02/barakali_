/// Thrown when account erasure is refused because the caller still has an
/// in-flight order (reserved or paid). GDPR Art.17(3)(b) permits declining
/// erasure while a contract is being performed; the user must settle open
/// orders first. The UI surfaces a specific message for this case.
class AccountDeletionBlockedException implements Exception {
  const AccountDeletionBlockedException();
}
