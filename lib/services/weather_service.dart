import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

/// Simple weather service using OpenWeatherMap API
/// Fetches current temperature based on GPS location
class WeatherService {
  // OpenWeatherMap API key - Free tier: 1,000 calls/day
  // Sign up at: https://openweathermap.org/api
  static const String _apiKey = '3a0f7cfe497c832c00709534169c585e';
  static const String _baseUrl =
      'https://api.openweathermap.org/data/2.5/weather';

  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  double? _currentTemperature; // Celsius
  DateTime? _lastUpdate;
  Timer? _updateTimer;

  // Cache duration: 10 minutes (free tier allows more frequent updates if needed)
  static const Duration _cacheDuration = Duration(minutes: 10);

  double? get currentTemperature => _currentTemperature;
  // Expose API key for other services (e.g., hazard alerts)
  static String get apiKey => _apiKey;

  /// Start periodic weather updates
  void startUpdates() {
    _updateWeather();
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(_cacheDuration, (_) => _updateWeather());
  }

  /// Stop periodic updates
  void stopUpdates() {
    _updateTimer?.cancel();
  }

  /// Fetch current weather based on device location
  Future<void> _updateWeather() async {
    // Check if we need to update (respect cache duration)
    if (_lastUpdate != null &&
        DateTime.now().difference(_lastUpdate!) < _cacheDuration) {
      return; // Use cached data
    }

    try {
      // Get current location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy:
            LocationAccuracy.low, // Low accuracy is fine for weather
      );

      // Build API URL with coordinates
      final url = Uri.parse(
        '$_baseUrl?lat=${position.latitude}&lon=${position.longitude}&appid=$_apiKey&units=metric',
      );

      // Make HTTP request
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _currentTemperature = (data['main']['temp'] as num).toDouble();
        _lastUpdate = DateTime.now();

        print('Weather updated: ${_currentTemperature?.toStringAsFixed(1)}°C');
      } else if (response.statusCode == 401) {
        print(
          'Weather API: Invalid API key. Get free key from openweathermap.org',
        );
      } else {
        print('Weather API error: ${response.statusCode}');
      }
    } catch (e) {
      print('Weather fetch error: $e');
      // Don't update temperature on error, keep previous value
    }
  }

  /// Manual weather fetch (for immediate update)
  Future<double?> fetchTemperature() async {
    await _updateWeather();
    return _currentTemperature;
  }

  void dispose() {
    _updateTimer?.cancel();
  }
}
