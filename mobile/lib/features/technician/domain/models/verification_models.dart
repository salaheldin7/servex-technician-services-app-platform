class VerificationStatus {
  final bool faceVerified;
  final bool docsUploaded;
  final String status; // none, pending, face_done, docs_done, verified, rejected
  final String rejectionReason;

  VerificationStatus({
    this.faceVerified = false,
    this.docsUploaded = false,
    this.status = 'none',
    this.rejectionReason = '',
  });

  factory VerificationStatus.fromJson(Map<String, dynamic> json) {
    return VerificationStatus(
      faceVerified: json['face_verified'] ?? false,
      docsUploaded: json['docs_uploaded'] ?? false,
      status: json['status'] ?? 'none',
      rejectionReason: json['rejection_reason'] ?? '',
    );
  }

  bool get isFullyVerified => status == 'verified';
  bool get needsFace => !faceVerified;
  bool get needsDocs => faceVerified && !docsUploaded;
  bool get needsServices => docsUploaded;
}

class TechnicianService {
  final String id;
  final String technicianId;
  final String categoryId;
  final double hourlyRate;
  final bool isActive;
  final String categoryNameEn;
  final String categoryNameAr;
  final String categoryIcon;

  TechnicianService({
    required this.id,
    required this.technicianId,
    required this.categoryId,
    required this.hourlyRate,
    this.isActive = true,
    this.categoryNameEn = '',
    this.categoryNameAr = '',
    this.categoryIcon = '',
  });

  factory TechnicianService.fromJson(Map<String, dynamic> json) {
    return TechnicianService(
      id: json['id'] ?? '',
      technicianId: json['technician_id'] ?? '',
      categoryId: json['category_id'] ?? '',
      hourlyRate: (json['hourly_rate'] ?? 0).toDouble(),
      isActive: json['is_active'] ?? true,
      categoryNameEn: json['category_name_en'] ?? '',
      categoryNameAr: json['category_name_ar'] ?? '',
      categoryIcon: json['category_icon'] ?? '',
    );
  }

  String categoryName(bool isArabic) =>
      isArabic ? categoryNameAr : categoryNameEn;
}

class ServiceLocation {
  final String id;
  final String technicianId;
  final String countryId;
  final String governorateId;
  final String? cityId;
  final String countryNameEn;
  final String countryNameAr;
  final String governorateNameEn;
  final String governorateNameAr;
  final String cityNameEn;
  final String cityNameAr;

  ServiceLocation({
    required this.id,
    required this.technicianId,
    required this.countryId,
    required this.governorateId,
    this.cityId,
    this.countryNameEn = '',
    this.countryNameAr = '',
    this.governorateNameEn = '',
    this.governorateNameAr = '',
    this.cityNameEn = '',
    this.cityNameAr = '',
  });

  factory ServiceLocation.fromJson(Map<String, dynamic> json) {
    return ServiceLocation(
      id: json['id'] ?? '',
      technicianId: json['technician_id'] ?? '',
      countryId: json['country_id'] ?? '',
      governorateId: json['governorate_id'] ?? '',
      cityId: json['city_id'],
      countryNameEn: json['country_name_en'] ?? '',
      countryNameAr: json['country_name_ar'] ?? '',
      governorateNameEn: json['governorate_name_en'] ?? '',
      governorateNameAr: json['governorate_name_ar'] ?? '',
      cityNameEn: json['city_name_en'] ?? '',
      cityNameAr: json['city_name_ar'] ?? '',
    );
  }

  String displayName(bool isArabic) {
    final country = isArabic ? countryNameAr : countryNameEn;
    final gov = isArabic ? governorateNameAr : governorateNameEn;
    final city = isArabic ? cityNameAr : cityNameEn;
    if (city.isNotEmpty) return '$country > $gov > $city';
    return '$country > $gov (${isArabic ? "كل المدن" : "All cities"})';
  }
}
