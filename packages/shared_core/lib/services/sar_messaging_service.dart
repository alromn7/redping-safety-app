import '../models/sar_incident.dart';
import '../models/sar_message.dart';

abstract class SARMessagingServiceCore {
  Future<void> initialize();
  Stream<List<SARIncidentCore>> get incidentsStream;
  Future<void> refreshIncidents();
  Future<void> postIncidentUpdate(String incidentId, String content);
  Stream<List<SARMessageCore>> messagesStream(String incidentId);
  Future<void> postMessage(String incidentId, SARMessageCore message);
}
