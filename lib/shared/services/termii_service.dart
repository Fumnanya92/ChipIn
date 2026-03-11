import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:chipin/core/config/app_constants.dart';

class TermiiService {
  static Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    final url = Uri.parse('${AppConstants.termiiBaseUrl}/api/sms/otp/send');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'api_key': AppConstants.termiiApiKey,
        'message_type': 'NUMERIC',
        'to': phoneNumber,
        'from': AppConstants.termiiSenderId,
        'channel': AppConstants.termiiChannel,
        'pin_attempts': 3,
        'pin_time_to_live': 5,
        'pin_length': 6,
        'pin_placeholder': '< 1234 >',
        'message_text': 'Your ChipIn verification code is < 1234 >. Valid for 5 minutes.',
        'pin_type': 'NUMERIC',
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to send OTP: ${response.body}');
    }
  }

  static Future<bool> verifyOtp({
    required String pinId,
    required String pin,
  }) async {
    final url = Uri.parse('${AppConstants.termiiBaseUrl}/api/sms/otp/verify');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'api_key': AppConstants.termiiApiKey,
        'pin_id': pinId,
        'pin': pin,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['verified'] == true || data['msisdn'] != null;
    }
    return false;
  }
}
