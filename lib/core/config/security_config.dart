class SecurityConfig {
  static const bool enableRequestSigning = bool.fromEnvironment(
    'ENABLE_REQUEST_SIGNING',
    defaultValue: false,
  );

  static const bool enableTlsPinning = bool.fromEnvironment(
    'ENABLE_TLS_PINNING',
    defaultValue: false,
  );

  /// When true, the client will attempt to attach a Play Integrity token
  /// to outgoing requests under a best-effort policy.
  static const bool enablePlayIntegrityHeader = bool.fromEnvironment(
    'ENABLE_PLAY_INTEGRITY_HEADER',
    defaultValue: true,
  );

  /// When true, non-GET API calls will fail fast on the client if a
  /// Play Integrity token could not be obtained. Server-side checks are
  /// still authoritative; this only adds a client guardrail.
  static const bool requirePlayIntegrityForWrites = bool.fromEnvironment(
    'REQUIRE_PLAY_INTEGRITY_FOR_WRITES',
    defaultValue: false,
  );

  /// When true, non-GET API calls on iOS will fail fast on the client
  /// if the device is detected as jailbroken via the native security plugin.
  static const bool requireIosRuntimeIntegrityForWrites = bool.fromEnvironment(
    'REQUIRE_IOS_RUNTIME_INTEGRITY_FOR_WRITES',
    defaultValue: false,
  );

  static const String expectedAndroidSignatureSha256 = String.fromEnvironment(
    'EXPECTED_ANDROID_SIG_SHA256',
    defaultValue: '',
  );

  static const String signingKeyStorageKey = 'sec.hmac.v1';
}
