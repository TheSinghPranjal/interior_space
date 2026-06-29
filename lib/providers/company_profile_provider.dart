import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/company_profile.dart';
import '../services/company_profile_storage_service.dart';

final companyProfileProvider =
    StateNotifierProvider<CompanyProfileNotifier, CompanyProfile>((ref) {
  return CompanyProfileNotifier(ref.read(companyProfileStorageProvider));
});

class CompanyProfileNotifier extends StateNotifier<CompanyProfile> {
  CompanyProfileNotifier(this._storage) : super(const CompanyProfile()) {
    _load();
  }

  final CompanyProfileStorageService _storage;

  Future<void> _load() async {
    state = await _storage.load();
  }

  Future<void> _persist() => _storage.save(state);

  Future<void> updateCompanyName(String value) async {
    state = state.copyWith(companyName: value);
    await _persist();
  }

  Future<void> updateAddress(String value) async {
    state = state.copyWith(address: value);
    await _persist();
  }

  Future<void> updateContactNumber(String value) async {
    state = state.copyWith(contactNumber: value);
    await _persist();
  }

  Future<void> updateEmail(String value) async {
    state = state.copyWith(email: value);
    await _persist();
  }

  Future<void> pickLogo() async {
    final path = await _storage.pickAndSaveImage(prefix: 'logo');
    if (path == null) return;

    final oldPath = state.logoPath;
    state = state.copyWith(logoPath: path);
    await _persist();
    await _storage.deleteImageFile(oldPath);
  }

  Future<void> pickCoverImage() async {
    final path = await _storage.pickAndSaveImage(prefix: 'cover');
    if (path == null) return;

    final oldPath = state.coverImagePath;
    state = state.copyWith(coverImagePath: path);
    await _persist();
    await _storage.deleteImageFile(oldPath);
  }

  Future<void> removeLogo() async {
    final oldPath = state.logoPath;
    state = state.copyWith(clearLogo: true);
    await _persist();
    await _storage.deleteImageFile(oldPath);
  }

  Future<void> removeCoverImage() async {
    final oldPath = state.coverImagePath;
    state = state.copyWith(clearCover: true);
    await _persist();
    await _storage.deleteImageFile(oldPath);
  }
}
