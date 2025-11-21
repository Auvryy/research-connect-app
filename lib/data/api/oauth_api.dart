import 'package:url_launcher/url_launcher.dart';
import 'dio_client.dart';
import '../user_info.dart';

class OAuthAPI {
  /// Sign in with Google using browser-based OAuth flow
  static Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      print('Starting Google OAuth flow...');
      
      // Construct the OAuth URL pointing to your backend
      final authUrl = Uri.parse('https://carlie-vile-workably.ngrok-free.dev/api/oauth/login?redirect_url=flutter');
      
      print('Opening auth URL: $authUrl');
      
      // Open the URL in the system browser
      if (await canLaunchUrl(authUrl)) {
        final launched = await launchUrl(
          authUrl,
          mode: LaunchMode.externalApplication,
        );
        
        if (!launched) {
          return {
            'ok': false,
            'status': 500,
            'message': 'Failed to open browser',
          };
        }
        
        // Note: The actual callback handling would need to be done through deep links
        // For now, we'll return a pending status
        return {
          'ok': false,
          'status': 202,
          'message': 'OAuth flow initiated. Complete login in browser.',
        };
      } else {
        return {
          'ok': false,
          'status': 500,
          'message': 'Cannot launch browser',
        };
      }
      
    } catch (e) {
      print('Google OAuth error: $e');
      return {
        'ok': false,
        'status': 500,
        'message': 'Google login failed: ${e.toString()}',
      };
    }
  }
}
