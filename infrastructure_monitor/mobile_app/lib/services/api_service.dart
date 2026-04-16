import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  // IMPORTANT: Since your phone is testing the app physically, it needs the Desktop's 
  // actual Wi-Fi IP address to connect to the fastAPI server!
  // I found your IP address via ipconfig: 10.5.136.28
  static const String baseUrl = 'http://10.5.136.28:8000';

  static Future<Map<String, dynamic>> analyzeImage(String imagePath) async {
    var uri = Uri.parse('$baseUrl/api/analyze/image');
    
    // Create a Multipart Request to upload the image file to Python
    var request = http.MultipartRequest('POST', uri);
    
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imagePath,
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    try {
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        return json.decode(responseData);
      } else {
        throw Exception('Failed to analyze image. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print("CONNECTION ERROR: Make sure API is running via 'python api.py'");
      throw Exception('Network Error: $e');
    }
  }

  // Helper url strictly for rendering Images returned by the API
  static String getImageUrl(String incidentId) {
    return '$baseUrl/api/files/$incidentId';
  }
}
