import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ar'),
  ];

  bool get isArabic => locale.languageCode == 'ar';

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_name': 'Servex',
      'hello': 'Hello',
      'login': 'Login',
      'register': 'Register',
      'email': 'Email',
      'password': 'Password',
      'phone': 'Phone Number',
      'full_name': 'Full Name',
      'otp_verification': 'OTP Verification',
      'enter_otp': 'Enter the code sent to your phone',
      'verify': 'Verify',
      'resend_otp': 'Resend Code',
      'home': 'Home',
      'bookings': 'Bookings',
      'chat': 'Chat',
      'wallet': 'Wallet',
      'profile': 'Profile',
      'settings': 'Settings',
      'search_services': 'Search services...',
      'no_results_found': 'No services found',
      'pick_location_on_map': 'Pick location on map',
      'tap_map_to_select': 'Tap on the map to select your location',
      'confirm_location': 'Confirm Location',
      'select_location': 'Select Location',
      'nearby_technicians': 'Nearby Technicians',
      'categories': 'Categories',
      'book_now': 'Book Now',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'cancel_booking': 'Cancel Booking',
      'rate_technician': 'Rate Technician',
      'submit_rating': 'Submit Rating',
      'write_review': 'Write a review...',
      'tracking': 'Tracking',
      'technician_on_way': 'Technician is on the way',
      'technician_arrived': 'Technician has arrived',
      'job_in_progress': 'Job in progress',
      'job_completed': 'Job completed',
      'enter_arrival_code': 'Enter Arrival Code',
      'arrival_code_hint': 'Enter the 6-digit code from your customer',
      'balance': 'Balance',
      'transactions': 'Transactions',
      'withdraw': 'Withdraw',
      'earnings': 'Earnings',
      'go_online': 'Go Online',
      'go_offline': 'Go Offline',
      'accept': 'Accept',
      'decline': 'Decline',
      'new_booking_request': 'New Booking Request',
      'no_bookings': 'No bookings yet',
      'support': 'Support',
      'create_ticket': 'Create Ticket',
      'my_tickets': 'My Tickets',
      'language': 'Language',
      'dark_mode': 'Dark Mode',
      'delete_account': 'Delete Account',
      'logout': 'Logout',
      'customer': 'Customer',
      'technician': 'Technician',
      'select_role': 'Select your role',
      'waiting_approval': 'Waiting for Approval',
      'waiting_approval_desc':
          'Your technician profile is being reviewed. We\'ll notify you once approved.',
      'upload_documents': 'Upload Documents',
      'id_card': 'ID Card',
      'certification': 'Certification',
      'address': 'Address',
      'description': 'Description',
      'schedule_time': 'Schedule Time',
      'total': 'Total',
      'payment_method': 'Payment Method',
      'cash': 'Cash',
      'card': 'Card',
      'payment_success': 'Payment Successful',
      'today': 'Today',
      'this_week': 'This Week',
      'this_month': 'This Month',
      'completed_jobs': 'Completed Jobs',
      'pending_jobs': 'Pending Jobs',
      'rating': 'Rating',
      'strikes': 'Strikes',
      'type_message': 'Type a message...',
      'send': 'Send',
      'error_occurred': 'An error occurred',
      'try_again': 'Try Again',
      'no_internet': 'No internet connection',
      'loading': 'Loading...',
      // Property types
      'select_property_type': 'Select Property Type',
      'your_property_type': 'Your Property Type',
      'select_property_type_desc': 'Select the type of property you need services for',
      'property_type': 'Property Type',
      'skip': 'Skip',
      'personal_residential': 'Personal Residential',
      'residential_compounds': 'Residential Compounds',
      'offices': 'Offices',
      'banks': 'Banks',
      'government_buildings': 'Government Buildings',
      'schools_universities': 'Schools & Universities',
      'hospitals_clinics': 'Hospitals & Clinics',
      'hotels': 'Hotels',
      'retail_shops': 'Retail Shops',
      'factories_warehouses': 'Factories & Warehouses',
      'restaurants_cafes': 'Restaurants & Cafes',
      'community_centers': 'Community Centers',
      'religious_buildings': 'Religious Buildings',
      'car_owners_garages': 'Car Owners / Garages',
      // Technician roles
      'electrician': 'Electrician',
      'plumber_role': 'Plumber',
      'carpenter_role': 'Carpenter',
      'painter_role': 'Painter',
      'ac_hvac_technician': 'AC & HVAC Technician',
      'cleaner_janitorial': 'Cleaner / Janitorial',
      'appliance_repair': 'Appliance Repair',
      'security_systems': 'Security Systems',
      'it_networking': 'IT / Networking',
      'pest_control': 'Pest Control',
      'gardener_landscaping': 'Gardener / Landscaping',
      'pool_maintenance': 'Pool Maintenance',
      'locksmith': 'Locksmith',
      'interior_designer': 'Interior Designer',
      'general_handyman': 'General Handyman',
      'car_mechanic': 'Car Mechanic',
      'car_electrician': 'Car Electrician',
      'car_wash_detailing': 'Car Wash & Detailing',
      'tire_wheel_specialist': 'Tire & Wheel Specialist',
      'car_ac_technician': 'Car AC Technician',
      // Service sections
      'all_services': 'All Services',
      'home_services_section': 'Home Services',
      'car_services': 'Car Services',
      'services': 'Services',
      'become_technician': 'Become a Technician',
      'become_technician_desc': 'Register as a technician and start offering your services',
      'select_your_services': 'Select Your Services',
      'choose_your_location': 'Choose Your Location',
      'register_as_technician': 'Register as Technician',
      'select_specialties': 'Select your specialties',
      'dont_have_account': "Don't have an account?",
      'already_have_account': 'Already have an account?',
      'confirm_password': 'Confirm Password',
      // Booking flow
      'your_location': 'Your Location',
      'getting_location': 'Getting your location...',
      'location_detected': 'Location detected automatically',
      'location_failed': 'Could not get location. Tap to retry.',
      'describe_your_problem': 'Describe Your Problem',
      'describe_problem_hint': 'Describe what you need help with...',
      'description_required': 'Please describe your problem',
      'find_technician': 'Find Nearby Technician',
      'booking_info_note': 'We will find the nearest available technician for you. The technician will set the price after inspecting the job.',
      'searching_nearby': 'Searching for nearby technicians...',
      // Verification flow
      'face_verification': 'Face Verification',
      'id_upload': 'Upload ID Card',
      'account_setup': 'Account Setup',
      'my_services': 'My Services',
      'my_services_areas': 'My Services & Areas',
      'manage_services': 'Manage your services and work areas',
      'service_areas': 'Service Areas',
      'add': 'Add',
      'remove': 'Remove',
      'remove_service': 'Remove Service',
      'remove_area': 'Remove Area',
      'no_services_added': 'No services added yet',
      'no_areas_added': 'No service areas added yet',
      'select_services': 'Select Your Services',
      'select_service_hint': 'Select the services you want to offer and set your hourly rate',
      'hourly_rate': 'Hourly Rate',
      'save_services': 'Save Services',
      'save_areas': 'Save Service Areas',
      'country': 'Country',
      'governorate': 'Governorate',
      'cities_label': 'Cities',
      'all_cities': 'All Cities',
      'select_country': 'Select Country',
      'select_governorate': 'Select Governorate',
      'add_area': 'Add This Area',
      'selected_areas': 'Selected Areas',
      'capture_photo': 'Capture Photo',
      'submit_continue': 'Submit & Continue',
      'step_of': 'Step %s of %s',
      'look_straight': 'Look straight at the camera',
      'turn_right': 'Turn your face to the right',
      'turn_left': 'Turn your face to the left',
      'camera': 'Camera',
      'gallery': 'Gallery',
      'front': 'Front',
      'back': 'Back',
      'max_files_hint': 'Maximum 2 files (front + back of ID)',
      'uploaded_files': 'Uploaded Files',
      'upload_id_hint': 'Capture or upload the front and back of your ID card (max 2 photos)',
      // Username
      'username': 'Username',
      'username_hint': 'Auto-generated. You can edit it.',
      'username_required': 'Username is required',
      'username_too_short': 'Username must be at least 3 characters',
      'username_taken': 'Username is already taken',
      'available': 'Available',
      'not_available': 'Not available',
      // Notifications
      'notifications': 'Notifications',
      'no_notifications': 'No notifications yet',
      'mark_all_read': 'Mark all as read',
      // Address
      'add_address': 'Add Address',
      'my_addresses': 'My Addresses',
      'street_name': 'Street Name',
      'building_name': 'Building Name',
      'building_number': 'Building Number',
      'save_address': 'Save Address',
      'choose_another_address': 'Choose another address',
      'add_new_address': 'Add new address',
      'enter_location_manually': 'Enter location manually',
      'auto_locate': 'Auto Locate',
      'default_address': 'Default',
      'set_as_default': 'Set as default',
      // Task status
      'technician_coming': 'Technician on the way',
      'technician_working': 'Technician working',
      'technician_finished': 'Technician finished',
      'task_closed': 'Task closed',
      // Booking flow
      'auto_assign': 'Auto Assign',
      'choose_technician': 'Choose Technician',
      'find_service': 'Find Service',
      'scan_now': 'Scan Now',
      'upload_file': 'Upload File',
      'scan_front': 'Scan Front',
      'scan_back': 'Scan Back',
    },
    'ar': {
      'app_name': 'سيرفيكس',
      'hello': 'مرحباً',
      'login': 'تسجيل الدخول',
      'register': 'إنشاء حساب',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'phone': 'رقم الهاتف',
      'full_name': 'الاسم الكامل',
      'otp_verification': 'التحقق من الرمز',
      'enter_otp': 'أدخل الرمز المرسل إلى هاتفك',
      'verify': 'تحقق',
      'resend_otp': 'إعادة إرسال الرمز',
      'home': 'الرئيسية',
      'bookings': 'الحجوزات',
      'chat': 'المحادثات',
      'wallet': 'المحفظة',
      'profile': 'الملف الشخصي',
      'settings': 'الإعدادات',
      'search_services': 'ابحث عن خدمات...',
      'no_results_found': 'لم يتم العثور على خدمات',
      'pick_location_on_map': 'حدد الموقع على الخريطة',
      'tap_map_to_select': 'اضغط على الخريطة لتحديد موقعك',
      'confirm_location': 'تأكيد الموقع',
      'select_location': 'حدد الموقع',
      'nearby_technicians': 'فنيون قريبون',
      'categories': 'الفئات',
      'book_now': 'احجز الآن',
      'cancel': 'إلغاء',
      'confirm': 'تأكيد',
      'cancel_booking': 'إلغاء الحجز',
      'rate_technician': 'قيّم الفني',
      'submit_rating': 'إرسال التقييم',
      'write_review': 'اكتب مراجعة...',
      'tracking': 'التتبع',
      'technician_on_way': 'الفني في الطريق',
      'technician_arrived': 'الفني وصل',
      'job_in_progress': 'العمل جارٍ',
      'job_completed': 'تم إكمال العمل',
      'enter_arrival_code': 'أدخل رمز الوصول',
      'arrival_code_hint': 'أدخل الرمز المكون من 6 أرقام من العميل',
      'balance': 'الرصيد',
      'transactions': 'المعاملات',
      'withdraw': 'سحب',
      'earnings': 'الأرباح',
      'go_online': 'متصل',
      'go_offline': 'غير متصل',
      'accept': 'قبول',
      'decline': 'رفض',
      'new_booking_request': 'طلب حجز جديد',
      'no_bookings': 'لا توجد حجوزات بعد',
      'support': 'الدعم',
      'create_ticket': 'إنشاء تذكرة',
      'my_tickets': 'تذاكري',
      'language': 'اللغة',
      'dark_mode': 'الوضع الداكن',
      'delete_account': 'حذف الحساب',
      'logout': 'تسجيل الخروج',
      'customer': 'عميل',
      'technician': 'فني',
      'select_role': 'اختر دورك',
      'waiting_approval': 'في انتظار الموافقة',
      'waiting_approval_desc':
          'يتم مراجعة ملفك كفني. سنبلغك فور الموافقة.',
      'upload_documents': 'رفع المستندات',
      'id_card': 'بطاقة الهوية',
      'certification': 'الشهادة',
      'address': 'العنوان',
      'description': 'الوصف',
      'schedule_time': 'حدد الوقت',
      'total': 'المجموع',
      'payment_method': 'طريقة الدفع',
      'cash': 'نقداً',
      'card': 'بطاقة',
      'payment_success': 'تمت عملية الدفع',
      'today': 'اليوم',
      'this_week': 'هذا الأسبوع',
      'this_month': 'هذا الشهر',
      'completed_jobs': 'المهام المكتملة',
      'pending_jobs': 'المهام المعلقة',
      'rating': 'التقييم',
      'strikes': 'المخالفات',
      'type_message': 'اكتب رسالة...',
      'send': 'إرسال',
      'error_occurred': 'حدث خطأ',
      'try_again': 'حاول مرة أخرى',
      'no_internet': 'لا يوجد اتصال بالإنترنت',
      'loading': 'جارٍ التحميل...',
      // Property types
      'select_property_type': 'اختر نوع العقار',
      'your_property_type': 'نوع العقار',
      'select_property_type_desc': 'اختر نوع العقار الذي تحتاج خدمات له',
      'property_type': 'نوع العقار',
      'skip': 'تخطي',
      'personal_residential': 'سكني شخصي',
      'residential_compounds': 'مجمعات سكنية',
      'offices': 'مكاتب',
      'banks': 'بنوك',
      'government_buildings': 'مباني حكومية',
      'schools_universities': 'مدارس وجامعات',
      'hospitals_clinics': 'مستشفيات وعيادات',
      'hotels': 'فنادق',
      'retail_shops': 'محلات تجارية',
      'factories_warehouses': 'مصانع ومستودعات',
      'restaurants_cafes': 'مطاعم ومقاهي',
      'community_centers': 'مراكز مجتمعية',
      'religious_buildings': 'مباني دينية (مساجد/كنائس)',
      'car_owners_garages': 'سيارات / ورش سيارات',
      // Technician roles
      'electrician': 'كهربائي',
      'plumber_role': 'سباك',
      'carpenter_role': 'نجار',
      'painter_role': 'دهان',
      'ac_hvac_technician': 'فني تكييف وتبريد',
      'cleaner_janitorial': 'عامل نظافة',
      'appliance_repair': 'صيانة الأجهزة المنزلية',
      'security_systems': 'تركيب أنظمة الأمن',
      'it_networking': 'فني شبكات وحواسيب',
      'pest_control': 'مكافحة الحشرات',
      'gardener_landscaping': 'بستاني / تنسيق حدائق',
      'pool_maintenance': 'صيانة مسابح',
      'locksmith': 'صانع مفاتيح',
      'interior_designer': 'مصمم داخلي / ديكور',
      'general_handyman': 'عامل صيانة متعدد',
      'car_mechanic': 'ميكانيكي سيارات',
      'car_electrician': 'كهربائي سيارات',
      'car_wash_detailing': 'غسيل وتلميع سيارات',
      'tire_wheel_specialist': 'فني إطارات وعجلات',
      'car_ac_technician': 'فني تكييف سيارات',
      // Service sections
      'all_services': 'جميع الخدمات',
      'home_services_section': 'الخدمات المنزلية',
      'car_services': 'خدمات السيارات',
      'services': 'الخدمات',
      'become_technician': 'كن فنياً',
      'become_technician_desc': 'سجّل كفني وابدأ بتقديم خدماتك',
      'select_your_services': 'اختر خدماتك',
      'choose_your_location': 'اختر موقعك',
      'register_as_technician': 'التسجيل كفني',
      'select_specialties': 'اختر تخصصاتك',
      'dont_have_account': 'ليس لديك حساب؟',
      'already_have_account': 'لديك حساب بالفعل؟',
      'confirm_password': 'تأكيد كلمة المرور',
      // Booking flow
      'your_location': 'موقعك',
      'getting_location': 'جارٍ تحديد موقعك...',
      'location_detected': 'تم تحديد الموقع تلقائياً',
      'location_failed': 'تعذر تحديد الموقع. اضغط للمحاولة.',
      'describe_your_problem': 'صف مشكلتك',
      'describe_problem_hint': 'صف ما تحتاج المساعدة فيه...',
      'description_required': 'يرجى وصف مشكلتك',
      'find_technician': 'ابحث عن فني قريب',
      'booking_info_note': 'سنبحث عن أقرب فني متاح لك. الفني سيحدد السعر بعد معاينة العمل.',
      'searching_nearby': 'جارٍ البحث عن فنيين قريبين...',
      // Verification flow
      'face_verification': 'التحقق من الوجه',
      'id_upload': 'تحميل بطاقة الهوية',
      'account_setup': 'إعداد الحساب',
      'my_services': 'خدماتي',
      'my_services_areas': 'خدماتي ومناطقي',
      'manage_services': 'إدارة خدماتك ومناطق عملك',
      'service_areas': 'مناطق الخدمة',
      'add': 'إضافة',
      'remove': 'حذف',
      'remove_service': 'حذف الخدمة',
      'remove_area': 'حذف المنطقة',
      'no_services_added': 'لم تضف خدمات بعد',
      'no_areas_added': 'لم تحدد مناطق خدمة بعد',
      'select_services': 'اختر خدماتك',
      'select_service_hint': 'اختر الخدمات التي تريد تقديمها وحدد أجرك بالساعة',
      'hourly_rate': 'الأجر بالساعة',
      'save_services': 'حفظ الخدمات',
      'save_areas': 'حفظ مناطق الخدمة',
      'country': 'الدولة',
      'governorate': 'المحافظة',
      'cities_label': 'المدن',
      'all_cities': 'كل المدن',
      'select_country': 'اختر الدولة',
      'select_governorate': 'اختر المحافظة',
      'add_area': 'أضف هذه المنطقة',
      'selected_areas': 'المناطق المحددة',
      'capture_photo': 'التقاط صورة',
      'submit_continue': 'إرسال والمتابعة',
      'step_of': 'الخطوة %s من %s',
      'look_straight': 'انظر مباشرة إلى الكاميرا',
      'turn_right': 'أدر وجهك إلى اليمين',
      'turn_left': 'أدر وجهك إلى اليسار',
      'camera': 'الكاميرا',
      'gallery': 'المعرض',
      'front': 'الوجه الأمامي',
      'back': 'الوجه الخلفي',
      'max_files_hint': 'الحد الأقصى 2 ملفات (وجه + خلف البطاقة)',
      'uploaded_files': 'الملفات المرفوعة',
      'upload_id_hint': 'التقط أو حمّل صورة الوجه الأمامي والخلفي لبطاقة الهوية',
      // Username
      'username': 'اسم المستخدم',
      'username_hint': 'يتم إنشاؤه تلقائياً. يمكنك تعديله.',
      'username_required': 'اسم المستخدم مطلوب',
      'username_too_short': 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل',
      'username_taken': 'اسم المستخدم مأخوذ',
      'available': 'متاح',
      'not_available': 'غير متاح',
      // Notifications
      'notifications': 'الإشعارات',
      'no_notifications': 'لا توجد إشعارات بعد',
      'mark_all_read': 'تحديد الكل كمقروء',
      // Address
      'add_address': 'إضافة عنوان',
      'my_addresses': 'عناويني',
      'street_name': 'اسم الشارع',
      'building_name': 'اسم المبنى',
      'building_number': 'رقم المبنى',
      'save_address': 'حفظ العنوان',
      'choose_another_address': 'اختر عنوان آخر',
      'add_new_address': 'إضافة عنوان جديد',
      'enter_location_manually': 'إدخال الموقع يدوياً',
      'auto_locate': 'تحديد تلقائي',
      'default_address': 'افتراضي',
      'set_as_default': 'تعيين كافتراضي',
      // Task status
      'technician_coming': 'الفني في الطريق',
      'technician_working': 'الفني يعمل',
      'technician_finished': 'الفني أنهى العمل',
      'task_closed': 'المهمة مغلقة',
      // Booking flow
      'auto_assign': 'تعيين تلقائي',
      'choose_technician': 'اختر فني',
      'find_service': 'ابحث عن خدمة',
      'scan_now': 'مسح الآن',
      'upload_file': 'رفع ملف',
      'scan_front': 'مسح الوجه الأمامي',
      'scan_back': 'مسح الوجه الخلفي',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // Convenience getters
  String get appName => translate('app_name');
  String get login => translate('login');
  String get register => translate('register');
  String get email => translate('email');
  String get password => translate('password');
  String get phone => translate('phone');
  String get fullName => translate('full_name');
  String get otpVerification => translate('otp_verification');
  String get enterOtp => translate('enter_otp');
  String get verify => translate('verify');
  String get resendOtp => translate('resend_otp');
  String get home => translate('home');
  String get bookings => translate('bookings');
  String get chat => translate('chat');
  String get wallet => translate('wallet');
  String get profile => translate('profile');
  String get settings => translate('settings');
  String get searchServices => translate('search_services');
  String get nearbyTechnicians => translate('nearby_technicians');
  String get categories => translate('categories');
  String get bookNow => translate('book_now');
  String get cancel => translate('cancel');
  String get confirm => translate('confirm');
  String get cancelBooking => translate('cancel_booking');
  String get rateTechnician => translate('rate_technician');
  String get submitRating => translate('submit_rating');
  String get writeReview => translate('write_review');
  String get tracking => translate('tracking');
  String get technicianOnWay => translate('technician_on_way');
  String get technicianArrived => translate('technician_arrived');
  String get jobInProgress => translate('job_in_progress');
  String get jobCompleted => translate('job_completed');
  String get enterArrivalCode => translate('enter_arrival_code');
  String get arrivalCodeHint => translate('arrival_code_hint');
  String get balance => translate('balance');
  String get transactions => translate('transactions');
  String get withdraw => translate('withdraw');
  String get earnings => translate('earnings');
  String get goOnline => translate('go_online');
  String get goOffline => translate('go_offline');
  String get accept => translate('accept');
  String get decline => translate('decline');
  String get newBookingRequest => translate('new_booking_request');
  String get noBookings => translate('no_bookings');
  String get support => translate('support');
  String get createTicket => translate('create_ticket');
  String get myTickets => translate('my_tickets');
  String get language => translate('language');
  String get darkMode => translate('dark_mode');
  String get deleteAccount => translate('delete_account');
  String get logout => translate('logout');
  String get customer => translate('customer');
  String get technician => translate('technician');
  String get selectRole => translate('select_role');
  String get waitingApproval => translate('waiting_approval');
  String get waitingApprovalDesc => translate('waiting_approval_desc');
  String get uploadDocuments => translate('upload_documents');
  String get idCard => translate('id_card');
  String get certification => translate('certification');
  String get address => translate('address');
  String get description => translate('description');
  String get scheduleTime => translate('schedule_time');
  String get total => translate('total');
  String get paymentMethod => translate('payment_method');
  String get cash => translate('cash');
  String get card => translate('card');
  String get paymentSuccess => translate('payment_success');
  String get today => translate('today');
  String get thisWeek => translate('this_week');
  String get thisMonth => translate('this_month');
  String get completedJobs => translate('completed_jobs');
  String get pendingJobs => translate('pending_jobs');
  String get rating => translate('rating');
  String get strikes => translate('strikes');
  String get typeMessage => translate('type_message');
  String get send => translate('send');
  String get errorOccurred => translate('error_occurred');
  String get tryAgain => translate('try_again');
  String get noInternet => translate('no_internet');
  String get loading => translate('loading');
  // Property types
  String get selectPropertyType => translate('select_property_type');
  String get yourPropertyType => translate('your_property_type');
  String get propertyType => translate('property_type');
  // Service sections
  String get allServices => translate('all_services');
  String get homeServicesSection => translate('home_services_section');
  String get carServices => translate('car_services');
  String get services => translate('services');
  String get becomeTechnician => translate('become_technician');
  String get becomeTechnicianDesc => translate('become_technician_desc');
  String get selectYourServices => translate('select_your_services');
  String get registerAsTechnician => translate('register_as_technician');
  String get selectSpecialties => translate('select_specialties');
  String get dontHaveAccount => translate('dont_have_account');
  String get alreadyHaveAccount => translate('already_have_account');
  String get confirmPassword => translate('confirm_password');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
