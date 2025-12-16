import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/local/local_cards_datasource.dart';
import '../data/local/local_settings_datasource.dart';
import '../data/remote/auth_service.dart';
import '../data/remote/remote_cards_datasource.dart';
import '../data/repositories/cards_repository.dart';

import 'settings_controller.dart';
import 'cards_controller.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.read(authServiceProvider).authStateChanges();
});

final localCardsDataSourceProvider = Provider<LocalCardsDataSource>((ref) {
  return LocalCardsDataSource();
});

final remoteCardsDataSourceProvider = Provider<RemoteCardsDataSource>((ref) {
  return RemoteCardsDataSource();
});

final cardsRepositoryProvider = Provider<CardsRepository>((ref) {
  return CardsRepository(
    local: ref.read(localCardsDataSourceProvider),
    remote: ref.read(remoteCardsDataSourceProvider),
    auth: ref.read(authServiceProvider),
  );
});

final localSettingsProvider = Provider<LocalSettingsDataSource>((ref) {
  return LocalSettingsDataSource();
});

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>(SettingsController.new);

final cardsControllerProvider =
    NotifierProvider<CardsController, CardsState>(CardsController.new);
