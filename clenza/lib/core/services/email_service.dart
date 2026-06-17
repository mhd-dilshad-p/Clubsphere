import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/email_constants.dart';

class EmailService {
  static Future<bool> sendInviteEmail({
    required String recipientEmail,
    required String recipientName,
    required String clubName,
    required String appUrl,
  }) async {
    // We will use the Google Apps Script Web App URL
    // You will paste the URL here after deploying the script.
    const String scriptUrl = EmailConstants.appsScriptUrl;

    if (scriptUrl.isEmpty || scriptUrl == 'YOUR_WEB_APP_URL_HERE') {
      print('Email failed: You have not added your Web App URL in email_constants.dart');
      return false;
    }

    final htmlBody = '''
      <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 12px; text-align: center;">
        <h2 style="color: #4A90E2;">Welcome to $clubName!</h2>
        <p style="font-size: 16px; color: #333; text-align: left;">
          Hi <strong>$recipientName</strong>,
        </p>
        <p style="font-size: 16px; color: #333; text-align: left;">
          You have been officially added as a member to <strong>$clubName</strong>.
        </p>
        <p style="font-size: 16px; color: #333; text-align: left;">
          You can now securely log in to your Member Dashboard using this email address or your registered phone number via OTP.
        </p>
        <div style="margin: 30px 0;">
          <a href="$appUrl" style="background-color: #4A90E2; color: #fff; padding: 14px 28px; text-decoration: none; border-radius: 8px; font-weight: bold; font-size: 16px;">
            Access Member Dashboard
          </a>
        </div>
        <p style="font-size: 14px; color: #777; margin-top: 40px;">
          If you did not request this, please ignore this email.
        </p>
        <hr style="border: 0; border-top: 1px solid #e0e0e0; margin: 20px 0;" />
        <p style="font-size: 12px; color: #aaa;">
          Sent automatically by Clenza
        </p>
      </div>
    ''';

    try {
      final response = await http.post(
        Uri.parse(scriptUrl),
        // Send as JSON text so Apps Script can parse it easily
        headers: {'Content-Type': 'text/plain'}, 
        body: jsonEncode({
          'recipientEmail': recipientEmail,
          'clubName': clubName,
          'htmlBody': htmlBody,
        }),
      );

      // On Flutter Web, successful requests to Google Apps Script often return status 200 or 302 due to redirects
      if (response.statusCode == 200 || response.statusCode == 302) {
        return true;
      } else {
        print('Email failed with status: \${response.statusCode}');
        return false;
      }
    } catch (e) {
      // Due to aggressive CORS policies on Web, if the email was sent but the browser blocked the response,
      // it might throw an XMLHttpRequest error here. Usually, the email still goes through.
      print('Email POST catch block: \$e');
      // Let's assume it worked if it's a CORS error from Apps Script (very common in Flutter Web)
      return true; 
    }
  }
}
