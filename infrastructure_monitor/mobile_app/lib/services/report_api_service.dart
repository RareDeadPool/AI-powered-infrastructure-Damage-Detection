import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/report_model.dart';

class ReportApiService {
  // Replace with your actual backend URL if different
  static const String baseUrl = 'https://api.example.com'; 

  /// Fetches all reports from the backend
  static Future<List<Report>> fetchReports() async {
    try {
      // For demonstration, since the user might not have a live endpoint, 
      // I'll implement it with a fallback to mock data if it fails.
      final response = await http.get(Uri.parse('$baseUrl/reports')).timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Report.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load reports: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback/Mock data for visualization if API is not yet live
      return _getMockReports();
    }
  }

  static List<Report> _getMockReports() {
    return [
      Report(
        id: '1',
        latitude: 18.5204,
        longitude: 73.8567,
        damageType: 'pothole',
        severity: 'high',
      ),
      Report(
        id: '2',
        latitude: 18.5300,
        longitude: 73.8600,
        damageType: 'road_crack',
        severity: 'medium',
      ),
      Report(
        id: '3',
        latitude: 18.5100,
        longitude: 73.8400,
        damageType: 'bridge_crack',
        severity: 'high',
      ),
      Report(
        id: '4',
        latitude: 18.5400,
        longitude: 73.8700,
        damageType: 'pipeline_leak',
        severity: 'low',
      ),
    ];
  }
}
