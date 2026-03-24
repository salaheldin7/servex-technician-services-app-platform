import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/verification_repository.dart';
import '../models/verification_models.dart';

final verificationRepositoryProvider = Provider<VerificationRepository>((ref) {
  return VerificationRepository(ref.read(apiClientProvider));
});

final verificationStatusProvider =
    FutureProvider.autoDispose<VerificationStatus>((ref) async {
  final repo = ref.read(verificationRepositoryProvider);
  final result = await repo.getVerificationStatus();
  return result.isSuccess
      ? result.data!
      : VerificationStatus(status: 'none');
});

final techServicesProvider =
    FutureProvider.autoDispose<List<TechnicianService>>((ref) async {
  final repo = ref.read(verificationRepositoryProvider);
  final result = await repo.getServices();
  return result.isSuccess ? result.data! : [];
});

final techServiceLocationsProvider =
    FutureProvider.autoDispose<List<ServiceLocation>>((ref) async {
  final repo = ref.read(verificationRepositoryProvider);
  final result = await repo.getLocations();
  return result.isSuccess ? result.data! : [];
});

// Notifier for managing the verification flow
class VerificationFlowNotifier extends Notifier<VerificationFlowState> {
  late final VerificationRepository _repo;

  @override
  VerificationFlowState build() {
    _repo = ref.read(verificationRepositoryProvider);
    return VerificationFlowState();
  }

  Future<bool> uploadFace(XFile front, XFile right, XFile left) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result =
          await _repo.uploadFace(frontImage: front, rightImage: right, leftImage: left);
      if (result.isSuccess) {
        state = state.copyWith(isLoading: false, faceUploaded: true);
        return true;
      }
      state =
          state.copyWith(isLoading: false, error: result.error?.message ?? 'Failed');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Upload error: $e');
      return false;
    }
  }

  Future<bool> uploadDocuments(List<XFile> files) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repo.uploadDocuments(files);
      if (result.isSuccess) {
        state = state.copyWith(isLoading: false, docsUploaded: true);
        return true;
      }
      state =
          state.copyWith(isLoading: false, error: result.error?.message ?? 'Failed');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Upload error: $e');
      return false;
    }
  }

  Future<bool> addServices(List<Map<String, dynamic>> services) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _repo.addServices(services);
    if (result.isSuccess) {
      state = state.copyWith(isLoading: false, servicesAdded: true);
      ref.invalidate(techServicesProvider);
      return true;
    }
    state =
        state.copyWith(isLoading: false, error: result.error?.message ?? 'Failed');
    return false;
  }

  Future<bool> addLocations(List<Map<String, dynamic>> locations) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _repo.addLocations(locations);
    if (result.isSuccess) {
      state = state.copyWith(isLoading: false, locationsAdded: true);
      ref.invalidate(techServiceLocationsProvider);
      return true;
    }
    state =
        state.copyWith(isLoading: false, error: result.error?.message ?? 'Failed');
    return false;
  }

  Future<bool> removeService(String serviceId) async {
    final result = await _repo.removeService(serviceId);
    if (result.isSuccess) {
      ref.invalidate(techServicesProvider);
      return true;
    }
    return false;
  }

  Future<bool> removeLocation(String locationId) async {
    final result = await _repo.removeLocation(locationId);
    if (result.isSuccess) {
      ref.invalidate(techServiceLocationsProvider);
      return true;
    }
    return false;
  }
}

class VerificationFlowState {
  final bool isLoading;
  final String? error;
  final bool faceUploaded;
  final bool docsUploaded;
  final bool servicesAdded;
  final bool locationsAdded;

  VerificationFlowState({
    this.isLoading = false,
    this.error,
    this.faceUploaded = false,
    this.docsUploaded = false,
    this.servicesAdded = false,
    this.locationsAdded = false,
  });

  VerificationFlowState copyWith({
    bool? isLoading,
    String? error,
    bool? faceUploaded,
    bool? docsUploaded,
    bool? servicesAdded,
    bool? locationsAdded,
  }) {
    return VerificationFlowState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      faceUploaded: faceUploaded ?? this.faceUploaded,
      docsUploaded: docsUploaded ?? this.docsUploaded,
      servicesAdded: servicesAdded ?? this.servicesAdded,
      locationsAdded: locationsAdded ?? this.locationsAdded,
    );
  }
}

final verificationFlowProvider =
    NotifierProvider<VerificationFlowNotifier, VerificationFlowState>(
        VerificationFlowNotifier.new);
