import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

class LocaleNotifier extends Notifier<Locale> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Locale build() {
    _loadSaved();
    return const Locale('en');
  }

  Future<void> _loadSaved() async {
    final saved = await _storage.read(key: 'app_locale');
    if (saved != null) {
      state = Locale(saved);
    }
  }

  Future<void> toggleLocale() async {
    final next = state.languageCode == 'en' ? const Locale('ar') : const Locale('en');
    state = next;
    await _storage.write(key: 'app_locale', value: next.languageCode);
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await _storage.write(key: 'app_locale', value: locale.languageCode);
  }
}
