/// Access levels for SAR (Search and Rescue) operations based on subscription tiers
enum SARAccessLevel {
  /// No SAR access - Free users
  none,

  /// Observer level - Can view SAR activities but not participate
  /// Available: Essential and Essential+ tiers
  observer,

  /// Participant level - Can join SAR operations as volunteer
  /// Available: Pro and Family tiers
  participant,

  /// Coordinator level - Can manage SAR organizations and operations
  /// Available: Ultra tier
  coordinator,
}

extension SARAccessLevelExtension on SARAccessLevel {
  /// Get display name for access level
  String get displayName {
    switch (this) {
      case SARAccessLevel.none:
        return 'No Access';
      case SARAccessLevel.observer:
        return 'Observer';
      case SARAccessLevel.participant:
        return 'Participant';
      case SARAccessLevel.coordinator:
        return 'Coordinator';
    }
  }

  /// Get description of access level capabilities
  String get description {
    switch (this) {
      case SARAccessLevel.none:
        return 'No access to SAR features. View emergency alerts only.';
      case SARAccessLevel.observer:
        return 'View SAR activities, receive notifications, connect to SAR network.';
      case SARAccessLevel.participant:
        return 'Join SAR operations, volunteer for missions, basic team coordination.';
      case SARAccessLevel.coordinator:
        return 'Full organization management, multi-team coordination, mission planning.';
    }
  }

  /// Get list of available features for this access level
  List<String> get availableFeatures {
    switch (this) {
      case SARAccessLevel.none:
        return ['View emergency alerts', 'Basic location sharing'];
      case SARAccessLevel.observer:
        return [
          'View SAR activities',
          'SAR network connection',
          'Emergency notifications',
          'Basic SAR information',
        ];
      case SARAccessLevel.participant:
        return [
          'Join SAR operations',
          'Volunteer registration',
          'Mission participation',
          'Basic team coordination',
          'SAR communication channels',
        ];
      case SARAccessLevel.coordinator:
        return [
          'Create and manage SAR organizations',
          'Multi-team coordination',
          'Mission planning and coordination',
          'Advanced SAR analytics',
          'Team member management',
          'Cross-organization collaboration',
        ];
    }
  }

  /// Check if this access level includes specific feature
  bool hasFeature(String feature) {
    switch (this) {
      case SARAccessLevel.none:
        return ['basicEmergencyAlerts', 'locationSharing'].contains(feature);
      case SARAccessLevel.observer:
        return [
          'basicEmergencyAlerts',
          'locationSharing',
          'sarNetworkConnection',
          'viewSARActivities',
          'emergencyNotifications',
        ].contains(feature);
      case SARAccessLevel.participant:
        return [
          'basicEmergencyAlerts',
          'locationSharing',
          'sarNetworkConnection',
          'viewSARActivities',
          'emergencyNotifications',
          'sarParticipation',
          'sarVolunteerRegistration',
          'missionParticipation',
          'sarCommunication',
        ].contains(feature);
      case SARAccessLevel.coordinator:
        return true; // Coordinator has access to all SAR features
    }
  }
}
