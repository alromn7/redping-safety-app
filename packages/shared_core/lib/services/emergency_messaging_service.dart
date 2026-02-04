import '../models/sos_session.dart';

abstract class EmergencyMessagingServiceCore {
  Future<void> initialize();
  Future<void> sendSOS(SOSSessionCore session, {String? message, Map<String, dynamic>? extras});
}
