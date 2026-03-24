class Country {
  final String id;
  final String nameEn;
  final String nameAr;
  final String code;
  final String phoneCode;
  final String currencyCode;
  final String currencySymbol;

  Country({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.code,
    this.phoneCode = '',
    this.currencyCode = '',
    this.currencySymbol = '',
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      id: json['id'] ?? '',
      nameEn: json['name_en'] ?? '',
      nameAr: json['name_ar'] ?? '',
      code: json['code'] ?? '',
      phoneCode: json['phone_code'] ?? '',
      currencyCode: json['currency_code'] ?? '',
      currencySymbol: json['currency_symbol'] ?? '',
    );
  }

  String name(bool isArabic) => isArabic ? nameAr : nameEn;
}

class Governorate {
  final String id;
  final String countryId;
  final String nameEn;
  final String nameAr;
  final String code;

  Governorate({
    required this.id,
    required this.countryId,
    required this.nameEn,
    required this.nameAr,
    this.code = '',
  });

  factory Governorate.fromJson(Map<String, dynamic> json) {
    return Governorate(
      id: json['id'] ?? '',
      countryId: json['country_id'] ?? '',
      nameEn: json['name_en'] ?? '',
      nameAr: json['name_ar'] ?? '',
      code: json['code'] ?? '',
    );
  }

  String name(bool isArabic) => isArabic ? nameAr : nameEn;
}

class City {
  final String id;
  final String governorateId;
  final String nameEn;
  final String nameAr;
  final String code;

  City({
    required this.id,
    required this.governorateId,
    required this.nameEn,
    required this.nameAr,
    this.code = '',
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'] ?? '',
      governorateId: json['governorate_id'] ?? '',
      nameEn: json['name_en'] ?? '',
      nameAr: json['name_ar'] ?? '',
      code: json['code'] ?? '',
    );
  }

  String name(bool isArabic) => isArabic ? nameAr : nameEn;
}
