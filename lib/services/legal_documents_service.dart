import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing legal document acceptance and status
class LegalDocumentsService {
  static const String _termsAcceptedKey = 'terms_conditions_accepted';
  static const String _privacyAcceptedKey = 'privacy_policy_accepted';
  static const String _securityAcceptedKey = 'security_policy_accepted';
  static const String _usageAcceptedKey = 'usage_policy_accepted';
  static const String _complianceAcceptedKey =
      'compliance_requirements_accepted';
  static const String _paymentAcceptedKey = 'payment_policy_accepted';

  static const String _termsVersionKey = 'terms_conditions_version';
  static const String _privacyVersionKey = 'privacy_policy_version';
  static const String _securityVersionKey = 'security_policy_version';
  static const String _usageVersionKey = 'usage_policy_version';
  static const String _complianceVersionKey = 'compliance_requirements_version';
  static const String _paymentVersionKey = 'payment_policy_version';

  static const String _currentVersion = '1.1';

  SharedPreferences? _prefs;

  /// Initialize the service
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      debugPrint('LegalDocumentsService: Initialized successfully');
    } catch (e) {
      debugPrint('LegalDocumentsService: Error initializing - $e');
    }
  }

  /// Get acceptance status for Terms & Conditions
  bool get isTermsAccepted {
    if (_prefs == null) return false;
    final accepted = _prefs!.getBool(_termsAcceptedKey) ?? false;
    final version = _prefs!.getString(_termsVersionKey) ?? '';
    return accepted && version == _currentVersion;
  }

  /// Get acceptance status for Privacy Policy
  bool get isPrivacyAccepted {
    if (_prefs == null) return false;
    final accepted = _prefs!.getBool(_privacyAcceptedKey) ?? false;
    final version = _prefs!.getString(_privacyVersionKey) ?? '';
    return accepted && version == _currentVersion;
  }

  /// Get acceptance status for Security Policy
  bool get isSecurityAccepted {
    if (_prefs == null) return false;
    final accepted = _prefs!.getBool(_securityAcceptedKey) ?? false;
    final version = _prefs!.getString(_securityVersionKey) ?? '';
    return accepted && version == _currentVersion;
  }

  /// Get acceptance status for Usage Policy
  bool get isUsageAccepted {
    if (_prefs == null) return false;
    final accepted = _prefs!.getBool(_usageAcceptedKey) ?? false;
    final version = _prefs!.getString(_usageVersionKey) ?? '';
    return accepted && version == _currentVersion;
  }

  /// Get acceptance status for Compliance Requirements
  bool get isComplianceAccepted {
    if (_prefs == null) return false;
    final accepted = _prefs!.getBool(_complianceAcceptedKey) ?? false;
    final version = _prefs!.getString(_complianceVersionKey) ?? '';
    return accepted && version == _currentVersion;
  }

  /// Get acceptance status for Payment Policy
  bool get isPaymentAccepted {
    if (_prefs == null) return false;
    final accepted = _prefs!.getBool(_paymentAcceptedKey) ?? false;
    final version = _prefs!.getString(_paymentVersionKey) ?? '';
    return accepted && version == _currentVersion;
  }

  /// Check if all required documents are accepted
  bool get areAllDocumentsAccepted {
    return isTermsAccepted && isPrivacyAccepted && isSecurityAccepted;
  }

  /// Accept Terms & Conditions
  Future<void> acceptTerms() async {
    if (_prefs == null) return;
    await _prefs!.setBool(_termsAcceptedKey, true);
    await _prefs!.setString(_termsVersionKey, _currentVersion);
    debugPrint('LegalDocumentsService: Terms & Conditions accepted');
  }

  /// Accept Privacy Policy
  Future<void> acceptPrivacy() async {
    if (_prefs == null) return;
    await _prefs!.setBool(_privacyAcceptedKey, true);
    await _prefs!.setString(_privacyVersionKey, _currentVersion);
    debugPrint('LegalDocumentsService: Privacy Policy accepted');
  }

  /// Accept Security Policy
  Future<void> acceptSecurity() async {
    if (_prefs == null) return;
    await _prefs!.setBool(_securityAcceptedKey, true);
    await _prefs!.setString(_securityVersionKey, _currentVersion);
    debugPrint('LegalDocumentsService: Security Policy accepted');
  }

  /// Accept Usage Policy
  Future<void> acceptUsage() async {
    if (_prefs == null) return;
    await _prefs!.setBool(_usageAcceptedKey, true);
    await _prefs!.setString(_usageVersionKey, _currentVersion);
    debugPrint('LegalDocumentsService: Usage Policy accepted');
  }

  /// Accept Compliance Requirements
  Future<void> acceptCompliance() async {
    if (_prefs == null) return;
    await _prefs!.setBool(_complianceAcceptedKey, true);
    await _prefs!.setString(_complianceVersionKey, _currentVersion);
    debugPrint('LegalDocumentsService: Compliance Requirements accepted');
  }

  /// Accept Payment Policy
  Future<void> acceptPayment() async {
    if (_prefs == null) return;
    await _prefs!.setBool(_paymentAcceptedKey, true);
    await _prefs!.setString(_paymentVersionKey, _currentVersion);
    debugPrint('LegalDocumentsService: Payment Policy accepted');
  }

  /// Decline Terms & Conditions
  Future<void> declineTerms() async {
    if (_prefs == null) return;
    await _prefs!.setBool(_termsAcceptedKey, false);
    await _prefs!.remove(_termsVersionKey);
    debugPrint('LegalDocumentsService: Terms & Conditions declined');
  }

  /// Decline Privacy Policy
  Future<void> declinePrivacy() async {
    if (_prefs == null) return;
    await _prefs!.setBool(_privacyAcceptedKey, false);
    await _prefs!.remove(_privacyVersionKey);
    debugPrint('LegalDocumentsService: Privacy Policy declined');
  }

  /// Decline Security Policy
  Future<void> declineSecurity() async {
    if (_prefs == null) return;
    await _prefs!.setBool(_securityAcceptedKey, false);
    await _prefs!.remove(_securityVersionKey);
    debugPrint('LegalDocumentsService: Security Policy declined');
  }

  /// Decline Usage Policy
  Future<void> declineUsage() async {
    if (_prefs == null) return;
    await _prefs!.setBool(_usageAcceptedKey, false);
    await _prefs!.remove(_usageVersionKey);
    debugPrint('LegalDocumentsService: Usage Policy declined');
  }

  /// Decline Compliance Requirements
  Future<void> declineCompliance() async {
    if (_prefs == null) return;
    await _prefs!.setBool(_complianceAcceptedKey, false);
    await _prefs!.remove(_complianceVersionKey);
    debugPrint('LegalDocumentsService: Compliance Requirements declined');
  }

  /// Decline Payment Policy
  Future<void> declinePayment() async {
    if (_prefs == null) return;
    await _prefs!.setBool(_paymentAcceptedKey, false);
    await _prefs!.remove(_paymentVersionKey);
    debugPrint('LegalDocumentsService: Payment Policy declined');
  }

  /// Get last acceptance date for Terms & Conditions
  DateTime? getTermsAcceptanceDate() {
    if (_prefs == null) return null;
    final timestamp = _prefs!.getInt('${_termsAcceptedKey}_timestamp');
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  /// Get last acceptance date for Privacy Policy
  DateTime? getPrivacyAcceptanceDate() {
    if (_prefs == null) return null;
    final timestamp = _prefs!.getInt('${_privacyAcceptedKey}_timestamp');
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  /// Get last acceptance date for Security Policy
  DateTime? getSecurityAcceptanceDate() {
    if (_prefs == null) return null;
    final timestamp = _prefs!.getInt('${_securityAcceptedKey}_timestamp');
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  /// Get last acceptance date for Payment Policy
  DateTime? getPaymentAcceptanceDate() {
    if (_prefs == null) return null;
    final timestamp = _prefs!.getInt('${_paymentAcceptedKey}_timestamp');
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  /// Reset all acceptances (for testing or major updates)
  Future<void> resetAllAcceptances() async {
    if (_prefs == null) return;

    await Future.wait([
      _prefs!.remove(_termsAcceptedKey),
      _prefs!.remove(_privacyAcceptedKey),
      _prefs!.remove(_securityAcceptedKey),
      _prefs!.remove(_usageAcceptedKey),
      _prefs!.remove(_complianceAcceptedKey),
      _prefs!.remove(_paymentAcceptedKey),
      _prefs!.remove(_termsVersionKey),
      _prefs!.remove(_privacyVersionKey),
      _prefs!.remove(_securityVersionKey),
      _prefs!.remove(_usageVersionKey),
      _prefs!.remove(_complianceVersionKey),
      _prefs!.remove(_paymentVersionKey),
    ]);

    debugPrint('LegalDocumentsService: All acceptances reset');
  }

  /// Get current document version
  String get currentVersion => _currentVersion;

  /// Check if service is initialized
  bool get isInitialized => _prefs != null;
}
