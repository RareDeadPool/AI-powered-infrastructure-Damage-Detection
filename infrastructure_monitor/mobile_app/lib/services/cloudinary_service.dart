import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class CloudinaryService {
  static const String cloudName = "doceqyymo";
  static const String apiKey = "146198354664196";
  static const String apiSecret = "Nps183Xm9HNXoD6oTZLTdKs81cQ";

  /// Uploads an image to Cloudinary using a signed request.
  /// Returns the secure URL of the uploaded image or null on failure.
  static Future<String?> uploadImage(String filePath, {String? folder}) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        print('Cloudinary: File does not exist at $filePath');
        return null;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      // 1. Prepare parameters for signing
      final params = <String, String>{
        'timestamp': timestamp.toString(),
      };
      if (folder != null) {
        params['folder'] = folder;
      }

      // 2. Generate signature
      final signature = _generateSignature(params, apiSecret);

      // 3. Create Multipart Request
      final uri = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");
      final request = http.MultipartRequest("POST", uri);

      // Add file
      final stream = http.ByteStream(file.openRead());
      final length = await file.length();
      final multipartFile = http.MultipartFile(
        'file',
        stream,
        length,
        filename: p.basename(filePath),
      );
      request.files.add(multipartFile);

      // Add other fields
      request.fields['api_key'] = apiKey;
      request.fields['timestamp'] = timestamp.toString();
      request.fields['signature'] = signature;
      if (folder != null) {
        request.fields['folder'] = folder;
      }

      // 4. Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['secure_url'] as String;
      } else {
        print('Cloudinary Upload Failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Cloudinary Service Error: $e');
      return null;
    }
  }

  /// Generates a Cloudinary signature.
  /// SHA1(params_sorted_by_key_and_joined_by_&_and_=_ + apiSecret)
  static String _generateSignature(Map<String, String> params, String secret) {
    // Sort keys alphabetically
    final sortedKeys = params.keys.toList()..sort();
    
    // Create query-string like sequence
    final queryString = sortedKeys.map((key) => "$key=${params[key]}").join('&');
    
    // Append secret
    final toSign = queryString + secret;
    
    // Generate SHA1 hash
    return sha1.convert(utf8.encode(toSign)).toString();
  }
}
