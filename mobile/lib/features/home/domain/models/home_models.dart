class Category {
  final String id;
  final String nameEn;
  final String nameAr;
  final String? icon;
  final String? parentId;
  final int sortOrder;
  final bool isActive;
  final String type;
  final List<Category> children;

  Category({
    required this.id,
    this.nameEn = '',
    this.nameAr = '',
    this.icon,
    this.parentId,
    this.sortOrder = 0,
    this.isActive = true,
    this.type = 'technician_role',
    this.children = const [],
  });

  String name(String lang) => lang == 'ar' ? nameAr : nameEn;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? '',
      nameEn: json['name_en'] ?? '',
      nameAr: json['name_ar'] ?? '',
      icon: json['icon'],
      parentId: json['parent_id'],
      sortOrder: json['sort_order'] ?? 0,
      isActive: json['is_active'] ?? true,
      type: json['type'] ?? 'technician_role',
      children: (json['children'] as List?)
              ?.map((c) => Category.fromJson(c))
              .toList() ??
          [],
    );
  }
}

class Booking {
  final String id;
  final String code;
  final String userId;
  final String? technicianId;
  final String categoryId;
  final String status;
  final String taskStatus;
  final String description;
  final double latitude;
  final double longitude;
  final String address;
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int? durationMinutes;
  final double estimatedPrice;
  final double? finalPrice;
  final String paymentMethod;
  final String? arrivalCode;
  final String? categoryName;
  final String? technicianName;
  final String? technicianPhone;
  final String? technicianAvatar;
  final double? technicianRating;
  final String? customerName;
  final String? customerPhone;
  final String? countryId;
  final String? governorateId;
  final String? cityId;
  final String? addressId;
  final String? streetName;
  final String? buildingName;
  final String? buildingNumber;
  final String? floor;
  final String? apartment;
  final String? fullAddress;
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.code,
    required this.userId,
    this.technicianId,
    required this.categoryId,
    required this.status,
    this.taskStatus = 'searching',
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.scheduledAt,
    this.startedAt,
    this.completedAt,
    this.durationMinutes,
    this.estimatedPrice = 0,
    this.finalPrice,
    this.paymentMethod = 'cash',
    this.arrivalCode,
    this.categoryName,
    this.technicianName,
    this.technicianPhone,
    this.technicianAvatar,
    this.technicianRating,
    this.customerName,
    this.customerPhone,
    this.countryId,
    this.governorateId,
    this.cityId,
    this.addressId,
    this.streetName,
    this.buildingName,
    this.buildingNumber,
    this.floor,
    this.apartment,
    this.fullAddress,
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      userId: json['user_id'] ?? '',
      technicianId: json['technician_id'],
      categoryId: json['category_id'] ?? '',
      status: json['status'] ?? '',
      taskStatus: json['task_status'] ?? 'searching',
      description: json['description'] ?? '',
      latitude: (json['lat'] ?? json['latitude'] ?? 0).toDouble(),
      longitude: (json['lng'] ?? json['longitude'] ?? 0).toDouble(),
      address: json['address'] ?? '',
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.tryParse(json['scheduled_at'])
          : null,
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'])
          : null,
      durationMinutes: json['duration_minutes'],
      estimatedPrice: (json['estimated_price'] ?? json['estimated_cost'] ?? 0).toDouble(),
      finalPrice: (json['final_price'] ?? json['final_cost'])?.toDouble(),
      paymentMethod: json['payment_method'] ?? 'cash',
      arrivalCode: json['arrival_code'],
      categoryName: json['category_name'],
      technicianName: json['technician_name'],
      technicianPhone: json['technician_phone'],
      technicianAvatar: json['technician_avatar'],
      technicianRating: json['technician_rating']?.toDouble(),
      customerName: json['customer_name'] ?? json['user_name'],
      customerPhone: json['customer_phone'],
      countryId: json['country_id'],
      governorateId: json['governorate_id'],
      cityId: json['city_id'],
      addressId: json['address_id'],
      streetName: json['street_name'],
      buildingName: json['building_name'],
      buildingNumber: json['building_number'],
      floor: json['floor'],
      apartment: json['apartment'],
      fullAddress: json['full_address'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  bool get isActive =>
      ['assigned', 'driving', 'arrived', 'active'].contains(status);
  bool get isCancellable =>
      ['searching', 'assigned', 'driving'].contains(status);

  String get taskStatusDisplay {
    switch (taskStatus) {
      case 'searching':
        return 'Searching for technician';
      case 'technician_coming':
        return 'Technician on the way';
      case 'technician_working':
        return 'Technician working on your task';
      case 'technician_finished':
        return 'Technician finished';
      case 'task_closed':
        return 'Task closed';
      default:
        return status;
    }
  }
}

class NearbyTechnician {
  final String id;
  final String userId;
  final String fullName;
  final String? avatarUrl;
  final double rating;
  final int completedJobs;
  final double distance;
  final List<String> categories;

  NearbyTechnician({
    required this.id,
    required this.userId,
    required this.fullName,
    this.avatarUrl,
    this.rating = 0,
    this.completedJobs = 0,
    this.distance = 0,
    this.categories = const [],
  });

  factory NearbyTechnician.fromJson(Map<String, dynamic> json) {
    return NearbyTechnician(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      fullName: json['full_name'] ?? '',
      avatarUrl: json['avatar_url'],
      rating: (json['rating'] ?? 0).toDouble(),
      completedJobs: json['completed_jobs'] ?? 0,
      distance: (json['distance'] ?? 0).toDouble(),
      categories: List<String>.from(json['categories'] ?? []),
    );
  }
}
