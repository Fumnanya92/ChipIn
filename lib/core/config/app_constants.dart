class AppConstants {
  // Supabase
  static const String supabaseUrl = 'https://ttdablzltxnaeaohkibg.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR0ZGFibHpsdHhuYWVhb2hraWJnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMyNTUyMzYsImV4cCI6MjA4ODgzMTIzNn0.6irn8whLYFlAE-VZ-kgX7VexQkDcZCmHQcps6SrYM7o';

  // Termii (phone OTP)
  static const String termiiBaseUrl = 'https://v3.api.termii.com';
  static const String termiiApiKey =
      'TLhpohdBzYiCsusjSxaBhoayhoUSkeRBVpBMbWEUijXtDfbgwyYNpxfbcxvFpS';
  static const String termiiSenderId = 'ChipIn';
  static const String termiiChannel = 'generic';

  // App
  static const String appName = 'ChipIn';
  static const String appVersion = '1.0.0';

  // Trust score points
  static const int trustPhoneVerified = 20;
  static const int trustIdVerified = 40;
  static const int trustPaymentVerified = 20;
  static const int trustTrustedUser = 20;
  static const int trustPerCompletedSplit = 2;

  // Supabase Storage buckets
  static const String avatarsBucket = 'avatars';
  static const String listingImagesBucket = 'listing-images';
  static const String idDocumentsBucket = 'id-documents';

  // OTP
  static const int otpResendCooldownSeconds = 60;
  static const int otpExpirySeconds = 300;

  // Supabase table names
  static const String notificationsTable = 'notifications';

  // Notifications
  static const String matchNotificationChannel = 'match_requests';
  static const String messageNotificationChannel = 'messages';
  static const String paymentNotificationChannel = 'payments';
}
