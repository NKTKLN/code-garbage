import '../../domain/models/card_item.dart';
import '../local/local_cards_datasource.dart';
import '../remote/auth_service.dart';
import '../remote/remote_cards_datasource.dart';

class CardsRepository {
  final LocalCardsDataSource local;
  final RemoteCardsDataSource remote;
  final AuthService auth;

  CardsRepository({
    required this.local,
    required this.remote,
    required this.auth,
  });

  List<CardItem> getAllLocal() => local.getAll();

  Future<void> save(CardItem card) async {
    await local.upsert(card);

    final u = auth.currentUser;
    if (u != null) {
      await remote.upsert(u.uid, card);
    }
  }

  Future<void> softDelete(CardItem card) async {
    final updated = card.copyWith(
      deleted: true,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    await save(updated);
  }

  Future<void> syncFromCloudMerge() async {
    final u = auth.currentUser;
    if (u == null) return;

    final cloudCards = await remote.fetchAll(u.uid);
    final localCards = local.getAll();

    final localMap = {for (final c in localCards) c.id: c};
    final cloudMap = {for (final c in cloudCards) c.id: c};

    // 1) merge cloud -> local (if cloud newer)
    for (final cloud in cloudCards) {
      final loc = localMap[cloud.id];
      if (loc == null || cloud.updatedAtMs > loc.updatedAtMs) {
        await local.upsert(cloud);
      }
    }

    // 2) merge local -> cloud (if local newer or not in cloud)
    for (final loc in localCards) {
      final cloud = cloudMap[loc.id];
      if (cloud == null || loc.updatedAtMs > cloud.updatedAtMs) {
        await remote.upsert(u.uid, loc);
      }
    }
  }

  Stream<List<CardItem>>? watchCloud() {
    final u = auth.currentUser;
    if (u == null) return null;
    return remote.watchAll(u.uid);
  }
}
