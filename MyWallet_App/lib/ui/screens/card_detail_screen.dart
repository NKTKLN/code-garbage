import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barcode_widget/barcode_widget.dart';

import '../../domain/models/card_item.dart';
import '../../domain/models/enums.dart';
import '../../state/providers.dart';
import 'edit_card_screen.dart';

class CardDetailScreen extends ConsumerWidget {
  final String cardId;
  const CardDetailScreen({super.key, required this.cardId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(cardsControllerProvider).all;
    final ctrl = ref.read(cardsControllerProvider.notifier);

    final card = cards.where((c) => c.id == cardId).cast<CardItem?>().firstOrNull;
    if (card == null || card.deleted) {
      return Scaffold(
        appBar: AppBar(title: const Text('Card')),
        body: const Center(child: Text('Card not found')),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ctrl.markUsed(card);
    });

    final bg = Color(card.colorValue);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(card.name.isEmpty ? 'Card' : card.name),
        actions: [
          IconButton(
            onPressed: () => ctrl.toggleFavorite(card),
            icon: Icon(card.favorite ? Icons.star : Icons.star_border),
          ),
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EditCardScreen(initial: card)),
              );
            },
            icon: const Icon(Icons.edit),
          ),
          IconButton(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: const Color(0xFF1C1C1C),
                  title: const Text('Delete?'),
                  content: const Text('This will remove card (syncs to cloud if logged in).'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                  ],
                ),
              );
              if (ok == true) {
                await ctrl.delete(card);
                if (context.mounted) Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            card.name.isEmpty ? 'Без названия' : card.name,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 6),
                          if (card.description.trim().isNotEmpty)
                            Text(
                              card.description.trim(),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          else
                            const SizedBox.shrink(),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                _CodePanel(card: card),
                const SizedBox(height: 12),
                Text(
                  card.codeValue,
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w700),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CodePanel extends StatelessWidget {
  final CardItem card;
  const _CodePanel({required this.card});

  @override
  Widget build(BuildContext context) {
    final isQr = card.codeType == CodeType.qr;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: BarcodeWidget(
          barcode: isQr ? Barcode.qrCode() : Barcode.code128(),
          data: card.codeValue.isEmpty ? ' ' : card.codeValue,
          width: 260,
          height: isQr ? 260 : 120,
          drawText: false,
        ),
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
