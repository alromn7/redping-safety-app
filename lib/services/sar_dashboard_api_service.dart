import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/google_cloud_config.dart';

/// API service to mirror website SAR dashboard data for the mobile app
class SARDashboardApiService {
  SARDashboardApiService._();
  static final SARDashboardApiService _instance = SARDashboardApiService._();
  static SARDashboardApiService get instance => _instance;

  String get _base => GoogleCloudConfig.baseUrl; // e.g. https://.../api

  Future<Map<String, dynamic>> fetchAllDashboardData() async {
    final uri = Uri.parse('$_base/sar-dashboard/data?type=all');
    final resp = await http.get(uri, headers: GoogleCloudConfig.getApiHeaders());
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return data;
    }
    throw Exception('Failed to fetch SAR dashboard data: ${resp.statusCode}');
  }

  Future<List<dynamic>> fetchIncidents() async {
    final uri = Uri.parse('$_base/sar-dashboard/data?type=incidents');
    final resp = await http.get(uri, headers: GoogleCloudConfig.getApiHeaders());
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return (data['incidents'] as List?) ?? [];
    }
    throw Exception('Failed to fetch incidents: ${resp.statusCode}');
  }

  Future<Map<String, dynamic>> fetchStats() async {
    final uri = Uri.parse('$_base/sar-dashboard/data?type=stats');
    final resp = await http.get(uri, headers: GoogleCloudConfig.getApiHeaders());
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return (data['stats'] as Map<String, dynamic>? ) ?? <String, dynamic>{};
    }
    throw Exception('Failed to fetch stats: ${resp.statusCode}');
  }

  Future<List<dynamic>> fetchHelpRequests({String? status, int limit = 50}) async {
    final params = <String, String>{'limit': limit.toString()};
    if (status != null && status.isNotEmpty) params['status'] = status;
    final uri = Uri.parse('$_base/help-requests').replace(queryParameters: params);
    final resp = await http.get(uri, headers: GoogleCloudConfig.getApiHeaders());
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final list = data['data'] as List?; // API returns { success, data }
      return list ?? [];
    }
    throw Exception('Failed to fetch help requests: ${resp.statusCode}');
  }

  /// Optional: website communications history (mocked in route for now)
  Future<List<dynamic>> fetchCommunications({int limit = 50, int offset = 0}) async {
    final uri = Uri.parse('$_base/sar-dashboard/communication?limit=$limit&offset=$offset');
    final resp = await http.get(uri, headers: GoogleCloudConfig.getApiHeaders());
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final list = data['communications'] as List?;
      return list ?? [];
    }
    throw Exception('Failed to fetch communications: ${resp.statusCode}');
  }
}
