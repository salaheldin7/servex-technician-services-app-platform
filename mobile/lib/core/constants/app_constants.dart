class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'http://localhost:8080/api/v1';
  static const String wsUrl = 'ws://localhost:8081/ws';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh';
  static const String sendOtp = '/auth/otp/send';
  static const String verifyOtp = '/auth/otp/verify';
  static const String logout = '/settings/logout';
  static const String checkUsername = '/auth/check-username';
  static const String generateUsername = '/auth/generate-username';

  // Categories
  static const String categories = '/categories';

  // Users
  static const String userProfile = '/users/me';
  static const String users = '/users';

  // Technicians
  static const String technicians = '/technicians';
  static const String technicianRegister = '/technicians/register';
  static const String technicianProfile = '/technicians/me';
  static const String technicianLocation = '/technicians/me/location';
  static const String technicianOnline = '/technicians/me/online';
  static const String technicianEarnings = '/technicians/me/earnings';
  static const String technicianStats = '/technicians/me/stats';
  static const String nearbyTechnicians = '/technicians/nearby';

  // Technician Verification
  static const String verificationFace = '/technicians/verification/face';
  static const String verificationDocuments = '/technicians/verification/documents';
  static const String verificationDocumentsBase64 = '/technicians/verification/documents/base64';
  static const String verificationStatus = '/technicians/verification/status';

  // Technician Services
  static const String technicianServices = '/technicians/services';
  static String technicianServiceById(String id) => '/technicians/services/$id';

  // Technician Service Locations
  static const String technicianServiceLocations = '/technicians/service-locations';
  static String technicianServiceLocationById(String id) => '/technicians/service-locations/$id';

  // Technician Search
  static const String technicianSearch = '/technicians/search';
  static const String technicianAutoAssign = '/technicians/auto-assign';

  // Locations (public)
  static const String countries = '/locations/countries';
  static String governorates(String countryId) => '/locations/countries/$countryId/governorates';
  static String cities(String governorateId) => '/locations/governorates/$governorateId/cities';

  // Bookings
  static const String bookings = '/bookings';
  static const String pendingRequests = '/bookings/pending-requests';
  static String bookingById(String id) => '/bookings/$id';
  static String bookingAccept(String id) => '/bookings/$id/accept';
  static String bookingCancel(String id) => '/bookings/$id/cancel';
  static String bookingArrive(String id) => '/bookings/$id/arrive';
  static String bookingVerifyArrival(String id) => '/bookings/$id/verify-arrival';
  static String bookingStart(String id) => '/bookings/$id/start';
  static String bookingComplete(String id) => '/bookings/$id/complete';

  // Chat
  static String chatMessages(String bookingId) => '/chat/bookings/$bookingId/messages';
  static String chatSend(String bookingId) => '/chat/bookings/$bookingId/messages';

  // Payments
  static const String payments = '/payments/history';
  static String processPayment(String bookingId) => '/payments/bookings/$bookingId/pay';

  // Wallet
  static const String walletBalance = '/wallet/balance';
  static const String walletTransactions = '/wallet/transactions';
  static const String walletWithdraw = '/wallet/withdraw';

  // Ratings
  static String ratingCreate(String bookingId) => '/ratings/bookings/$bookingId';
  static String technicianRatings(String techId) => '/ratings/technicians/$techId';

  // Settings
  static const String settingsName = '/settings/name';
  static const String settingsPhone = '/settings/phone';
  static const String settingsEmail = '/settings/email';
  static const String settingsLanguage = '/settings/language';
  static const String settingsDeleteAccount = '/settings/account';

  // Support
  static const String supportTickets = '/support/tickets';
  static String supportTicketById(String id) => '/support/tickets/$id';
  static String supportTicketMessages(String id) => '/support/tickets/$id/messages';

  // Notifications
  static const String notifications = '/notifications';
  static const String notificationsUnreadCount = '/notifications/unread-count';
  static String notificationMarkRead(String id) => '/notifications/$id/read';
  static const String notificationsReadAll = '/notifications/read-all';

  // Addresses
  static const String addresses = '/addresses';
  static const String defaultAddress = '/addresses/default';
  static String addressSetDefault(String id) => '/addresses/$id/default';
  static String addressDelete(String id) => '/addresses/$id';
}

class AppConstants {
  AppConstants._();

  static const String appName = 'TechApp';
  static const int otpLength = 6;
  static const int otpExpirySeconds = 300;
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration wsReconnectDelay = Duration(seconds: 3);
  static const int maxWsReconnectAttempts = 5;
  static const double defaultMapZoom = 14.0;
  static const int maxFileUploadSizeMB = 10;

  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userRoleKey = 'user_role';
  static const String userIdKey = 'user_id';
  static const String propertyTypeKey = 'property_type';
  static const String languageKey = 'language';
  static const String themeKey = 'theme_mode';
  static const String onboardingKey = 'onboarding_complete';
}
