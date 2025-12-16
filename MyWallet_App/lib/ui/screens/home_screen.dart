import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/enums.dart';
import '../../state/providers.dart';
import '../widgets/card_tile_grid.dart';
import '../widgets/card_tile_list.dart';
import 'card_detail_screen.dart';
import 'edit_card_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final cardsState = ref.watch(cardsControllerProvider);
    final cardsCtrl = ref.read(cardsControllerProvider.notifier);

    final visible = ref.read(cardsControllerProvider.notifier).visible(settings);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MyWallet', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            tooltip: 'Favorites',
            icon: Icon(cardsState.favoritesOnly ? Icons.star : Icons.star_border),
            onPressed: cardsCtrl.toggleFavoritesOnly,
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: settings.layoutMode == LayoutMode.grid
          ? _Grid(
              cards: visible,
              onOpen: (c) async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CardDetailScreen(cardId: c.id)),
                );
              },
              onStar: (c) => cardsCtrl.toggleFavorite(c),
            )
          : _List(
              cards: visible,
              onOpen: (c) async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CardDetailScreen(cardId: c.id)),
                );
              },
              onStar: (c) => cardsCtrl.toggleFavorite(c),
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 8),
        child: FloatingActionButton(
          backgroundColor: const Color(0xFFEDEDED),
          foregroundColor: Colors.black,
          onPressed: () async {
            final empty = await cardsCtrl.createEmpty();
            // ignore: use_build_context_synchronously
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EditCardScreen(initial: empty)),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  final List cards;
  final void Function(dynamic) onOpen;
  final void Function(dynamic) onStar;

  const _Grid({required this.cards, required this.onOpen, required this.onStar});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemCount: cards.length,
      itemBuilder: (_, i) {
        final c = cards[i];
        return CardTileGrid(
          card: c,
          onTap: () => onOpen(c),
          onStar: () => onStar(c),
        );
      },
    );
  }
}

class _List extends StatelessWidget {
  final List cards;
  final void Function(dynamic) onOpen;
  final void Function(dynamic) onStar;

  const _List({required this.cards, required this.onOpen, required this.onStar});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 10, bottom: 100),
      itemCount: cards.length,
      itemBuilder: (_, i) {
        final c = cards[i];
        return CardTileList(
          card: c,
          onTap: () => onOpen(c),
          onStar: () => onStar(c),
        );
      },
    );
  }
}
