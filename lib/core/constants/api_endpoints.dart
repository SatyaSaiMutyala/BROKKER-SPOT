class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String login = 'user/auth/login';
  static const String signup = 'user/auth/register';
  static const String googleSignIn = 'user/auth/google-login';
  static const String appleSignIn = 'user/auth/apple-login';
  static const String registerDevice = 'user/auth/register-device';
  static const String forgotPassword = 'user/auth/forgot-password';
  static const String switchRole = 'user/auth/switch-role';

  // Profile
  static const String fileUpload = 'user/profile/file-upload';
  static const String editBrokerDetails = 'user/profile/edit-broker-details';
  static const String changePassword = 'user/profile/change-password';
  static const String getProfile = 'user/profile/get-profile';
  static const String editInfo = 'user/profile/edit-info';
  static const String editMobileNumber = 'user/profile/edit-mobilenumber';
  static const String editEmail = 'user/profile/edit-email';
  static const String verifyEmailOtp = 'user/profile/verify-email-otp';

  // Guest (no auth required)
  static const String guestFetchAllAnnouncements = 'guest/announcements/fetch-all';
  static const String guestFetchAnnouncementDetail = 'guest/announcements/fetch';

  // Announcements
  static const String addAnnouncement = 'user/announcements/add';
  static const String editAnnouncement = 'user/announcements/edit';
  static const String deleteAnnouncement = 'user/announcements/delete';
  static const String fetchAnnouncements = 'user/announcements/fetch';
  static const String fetchAnnouncementDetail = 'user/announcements/fetch';
  static const String fetchAllAnnouncements = 'user/announcements/fetch-all';
  static const String sendProposal = 'user/announcements/sent-proposal';
  // Meeting (announcements grouped by the conversations on them).
  // Filters: ?own=true | ?listing_type=1 | ?listing_type=2 | (none = all).
  static const String fetchMeetings = 'user/announcements/fetch-meetings';

  // Notifications
  static const String fetchNotifications = 'user/notifications/fetch';
  static const String fetchNotificationDetail = 'user/notifications/fetch';
  static const String markAllNotificationsRead = 'user/notifications/mark-all-read';
  static const String deleteNotification = 'user/notifications/delete';

  // Common reference data
  static const String fetchAmenities = 'user/common/fetch-amenities';
  static const String fetchCountries = 'user/common/fetch-countries';
  static const String fetchCities = 'user/common/fetch-cities';
  static const String fetchLocalities = 'user/common/fetch-localities';
  static const String fetchLanguages = 'user/common/fetch-languages';
  static const String fetchPropertyTypes = 'user/common/fetch-property-types';
}
