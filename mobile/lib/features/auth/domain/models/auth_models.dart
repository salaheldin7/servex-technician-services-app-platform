class User {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String username;
  final String role;
  final String? avatarUrl;
  final String language;
  final bool isActive;
  final bool? technicianApproved;
  final String? propertyType;
  final DateTime createdAt;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.username = '',
    required this.role,
    this.avatarUrl,
    this.language = 'en',
    this.isActive = true,
    this.technicianApproved,
    this.propertyType,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      username: json['username'] ?? '',
      role: json['role'] ?? 'customer',
      avatarUrl: json['avatar_url'],
      language: json['language'] ?? 'en',
      isActive: json['is_active'] ?? true,
      technicianApproved: json['technician_approved'],
      propertyType: json['property_type'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'username': username,
        'role': role,
        'avatar_url': avatarUrl,
        'language': language,
        'property_type': propertyType,
      };

  User copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? username,
    String? avatarUrl,
    String? language,
    bool? technicianApproved,
    String? propertyType,
  }) {
    return User(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      username: username ?? this.username,
      role: role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      language: language ?? this.language,
      isActive: isActive,
      technicianApproved: technicianApproved ?? this.technicianApproved,
      propertyType: propertyType ?? this.propertyType,
      createdAt: createdAt,
    );
  }
}

class AuthTokens {
  final String accessToken;
  final String refreshToken;

  AuthTokens({required this.accessToken, required this.refreshToken});

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['access_token'] ?? '',
      refreshToken: json['refresh_token'] ?? '',
    );
  }
}

class AuthState {
  final User? user;
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;

  AuthState({
    this.user,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    User? user,
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
