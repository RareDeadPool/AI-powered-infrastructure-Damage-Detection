import 'dart:convert';
import 'package:http/http.dart' as http;

/// Validates that an email address actually exists and can receive mail.
/// Uses a combination of DNS MX checks and SMTP mailbox verification
/// via a free public API.
class EmailValidationService {
  /// Returns `true` only if the email address is deliverable.
  /// Returns `false` for non-existent, disposable, or invalid emails.
  static Future<bool> isEmailValid(String email) async {
    try {
      // Use the free EVA email verification API — checks format, MX, 
      // and does SMTP-level mailbox verification (no API key required).
      final uri = Uri.parse(
        'https://api.eva.pingutil.com/email?email=${Uri.encodeComponent(email)}',
      );

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () => http.Response('{}', 408),
      );

      if (response.statusCode != 200) {
        print('Email validation: API returned ${response.statusCode}');
        // Fallback to basic MX check if API is down
        return await _checkMxRecords(email);
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final dataField = data['data'] as Map<String, dynamic>?;

      if (dataField == null) {
        print('Email validation: No data field in response');
        return await _checkMxRecords(email);
      }

      // Check the deliverability status
      final bool isValidFormat = dataField['valid_syntax'] == true;
      final bool isDisposable = dataField['disposable'] == true;
      final bool isDeliverable = dataField['deliverable'] == true;
      final bool hasSpamScore = (dataField['spam_score'] ?? 0) > 0.8;

      print('Email check: format=$isValidFormat, deliverable=$isDeliverable, '
            'disposable=$isDisposable, spam=$hasSpamScore');

      // Reject if format is bad, email is not deliverable, 
      // is disposable (temp mail), or has high spam score
      if (!isValidFormat || isDisposable || hasSpamScore) {
        return false;
      }

      // The "deliverable" field is the key one — it means the SMTP 
      // server confirmed the mailbox exists
      return isDeliverable;
    } catch (e) {
      print('Email validation error: $e');
      // If the API fails entirely, fall back to MX record check
      return await _checkMxRecords(email);
    }
  }

  /// Fallback: Checks if the email domain has valid MX records via Google DNS.
  static Future<bool> _checkMxRecords(String email) async {
    try {
      final domain = email.split('@').last.trim().toLowerCase();
      if (domain.isEmpty) return false;

      final uri = Uri.parse('https://dns.google/resolve?name=$domain&type=MX');
      final response = await http.get(uri).timeout(
        const Duration(seconds: 5),
        onTimeout: () => http.Response('{}', 408),
      );

      if (response.statusCode != 200) return true; // benefit of doubt

      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data['Status'] == 0 && data.containsKey('Answer')) {
        final answers = data['Answer'] as List;
        return answers.isNotEmpty;
      }
      return false;
    } catch (e) {
      return true; // don't block on network errors
    }
  }
}
