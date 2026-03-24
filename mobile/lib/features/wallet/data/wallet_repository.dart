import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_constants.dart';

class WalletBalance {
  final double balance;
  final double debt;

  WalletBalance({this.balance = 0, this.debt = 0});

  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    return WalletBalance(
      balance: (json['balance'] ?? 0).toDouble(),
      debt: (json['debt'] ?? 0).toDouble(),
    );
  }
}

class WalletTransaction {
  final String id;
  final String technicianId;
  final String type;
  final double amount;
  final String? bookingId;
  final String? description;
  final DateTime createdAt;

  WalletTransaction({
    required this.id,
    required this.technicianId,
    required this.type,
    required this.amount,
    this.bookingId,
    this.description,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] ?? '',
      technicianId: json['technician_id'] ?? '',
      type: json['type'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      bookingId: json['booking_id'],
      description: json['description'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  bool get isCredit => ['job_credit', 'debt_payment'].contains(type);
  bool get isDebit => ['commission', 'withdrawal', 'penalty', 'debt'].contains(type);
}

class WalletRepository {
  final ApiClient _apiClient;

  WalletRepository(this._apiClient);

  Future<ApiResult<WalletBalance>> getBalance() async {
    try {
      final response = await _apiClient.get(ApiConstants.walletBalance);
      return ApiResult.success(WalletBalance.fromJson(response.data));
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<List<WalletTransaction>>> getTransactions({
    int page = 1,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.walletTransactions,
        queryParameters: {'page': page, 'limit': 20},
      );
      final data = response.data;
      List rawList;
      if (data is List) {
        rawList = data;
      } else if (data is Map && data['transactions'] != null) {
        rawList = data['transactions'] as List;
      } else {
        rawList = [];
      }
      final list = rawList
          .map((e) => WalletTransaction.fromJson(e as Map<String, dynamic>))
          .toList();
      return ApiResult.success(list);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<void>> requestWithdrawal(double amount) async {
    try {
      await _apiClient.post(
        ApiConstants.walletWithdraw,
        data: {'amount': amount},
      );
      return ApiResult.success(null);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }
}
