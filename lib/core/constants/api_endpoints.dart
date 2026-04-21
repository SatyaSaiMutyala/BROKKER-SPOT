class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String login = 'user/auth/login';
  static const String signup = 'user/auth/register';
  static const String googleSignIn = 'user/auth/google-login';
  static const String appleSignIn = 'user/auth/apple-login';
  static const String registerDevice = 'user/auth/register-device';
  static const String forgotPassword = 'user/auth/forgot-password';

  // Profile
  static const String fileUpload = 'user/profile/file-upload';
  static const String editBrokerDetails = 'user/profile/edit-broker-details';
  static const String changePassword = 'user/profile/change-password';
  static const String getProfile = 'user/profile/get-profile';
  static const String editInfo = 'user/profile/edit-info';
  static const String editMobileNumber = 'user/profile/edit-mobilenumber';
  static const String editEmail = 'user/profile/edit-email';
  static const String verifyEmailOtp = 'user/profile/verify-email-otp';
}
