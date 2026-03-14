import '../models/profile_model.dart';
import 'api_service.dart';
import 'service_exception.dart';

class ProfileService {
  ProfileService(this._apiService);

  final ApiService _apiService;

  Future<ProfileModel> getProfile() {
    return _runSafely(
      _apiService.getProfile,
      fallbackMessage: 'Unable to load the household profile right now.',
    );
  }

  Future<ProfileModel> createProfile(ProfileModel profile) {
    return _runSafely(
      () => _apiService.createProfile(profile),
      fallbackMessage: 'Unable to create the household profile right now.',
    );
  }

  Future<ProfileModel> updateProfile(ProfileModel profile) {
    return _runSafely(
      () => _apiService.updateProfile(profile),
      fallbackMessage: 'Unable to update the household profile right now.',
    );
  }

  Future<ProfileModel> saveProfile(ProfileModel profile) {
    if (profile.id.isEmpty) {
      return createProfile(profile);
    }
    return updateProfile(profile);
  }

  Future<T> _runSafely<T>(
    Future<T> Function() operation, {
    required String fallbackMessage,
  }) async {
    try {
      return await operation();
    } on ApiException catch (error) {
      throw ServiceException(error.message);
    } catch (_) {
      throw ServiceException(fallbackMessage);
    }
  }
}
