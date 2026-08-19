class ConsentRecord {
  const ConsentRecord({
    required this.consentType,
    required this.documentVersion,
    required this.granted,
  });

  final String consentType;
  final String documentVersion;
  final bool granted;

  Map<String, dynamic> toJson() => {
    'consent_type': consentType,
    'document_version': documentVersion,
    'granted': granted,
  };
}
