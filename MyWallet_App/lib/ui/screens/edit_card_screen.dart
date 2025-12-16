import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/card_item.dart';
import '../../domain/models/enums.dart';
import '../../state/providers.dart';
import 'scan_screen.dart';

class EditCardScreen extends ConsumerStatefulWidget {
  final CardItem initial;
  const EditCardScreen({super.key, required this.initial});

  @override
  ConsumerState<EditCardScreen> createState() => _EditCardScreenState();
}

class _EditCardScreenState extends ConsumerState<EditCardScreen> {
  late CardItem _card;

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _card = widget.initial;
    _nameCtrl.text = _card.name;
    _descCtrl.text = _card.description;
    _codeCtrl.text = _card.codeValue;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = ref.read(cardsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Card', style: TextStyle(fontWeight: FontWeight.w500)),
        actions: [
          IconButton(
            onPressed: () async {
              final updated = _card.copyWith(
                name: _nameCtrl.text.trim(),
                description: _descCtrl.text.trim(),
                codeValue: _codeCtrl.text.trim(),
              );
              await ctrl.save(updated);
              if (context.mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.check),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
        children: [
          _SectionTitle('Name'),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              hintText: 'Some shop',
              filled: true,
              fillColor: Color(0xFF1B1B1B),
              border: OutlineInputBorder(borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 14),

          _SectionTitle('Description'),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Any notes (phone, address, membership info...)',
              filled: true,
              fillColor: Color(0xFF1B1B1B),
              border: OutlineInputBorder(borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 14),

          _SectionTitle('Code'),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Barcode / QR data',
                    filled: true,
                    fillColor: Color(0xFF1B1B1B),
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: () async {
                  final res = await Navigator.push<ScanResult?>(
                    context,
                    MaterialPageRoute(builder: (_) => const ScanScreen()),
                  );

                  if (res == null) return;

                  setState(() {
                    _card = _card.copyWith(codeType: res.codeType);
                    _codeCtrl.text = res.value;
                  });
                },
                icon: const Icon(Icons.qr_code_scanner),
              )
            ],
          ),
          const SizedBox(height: 10),

          _SectionTitle('Code Type'),
          Wrap(
            spacing: 10,
            children: CodeType.values.map((t) {
              final active = _card.codeType == t;
              return ChoiceChip(
                label: Text(t.name.toUpperCase()),
                selected: active,
                showCheckmark: false,
                onSelected: (_) => setState(() => _card = _card.copyWith(codeType: t)),
                selectedColor: const Color(0xFFE0E0E0),
                labelStyle: TextStyle(color: active ? Colors.black : Colors.white70, fontWeight: FontWeight.w700),
                backgroundColor: const Color(0xFF2A2A2A),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          _SectionTitle('Color'),
          _ColorPicker(
            selected: _card.colorValue,
            onPick: (v) => setState(() => _card = _card.copyWith(colorValue: v)),
          ),
          const SizedBox(height: 10),

          SwitchListTile(
            value: _card.favorite,
            onChanged: (v) => setState(() => _card = _card.copyWith(favorite: v)),
            title: const Text('Favorite'),
          ),

          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEDEDED),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () async {
              final updated = _card.copyWith(
                name: _nameCtrl.text.trim(),
                description: _descCtrl.text.trim(),
                codeValue: _codeCtrl.text.trim(),
              );
              await ctrl.save(updated);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white70)),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onPick;

  const _ColorPicker({required this.selected, required this.onPick});

  @override
  Widget build(BuildContext context) {
    const palette = <int>[
      // RED / PINK (clean, modern)
      0xFFE53935, // Red
      0xFFD81B60, // Pink
      0xFFEC407A, // Soft Pink
      0xFFAD1457, // Deep Pink

      // PURPLE / INDIGO
      0xFF8E24AA, // Purple
      0xFF6A1B9A, // Deep Purple
      0xFF5E35B1, // Indigo
      0xFF3949AB, // Indigo Blue

      // BLUE (fresh UI blues)
      0xFF1E88E5, // Blue
      0xFF1565C0, // Deep Blue
      0xFF039BE5, // Light Blue
      0xFF00ACC1, // Cyan

      // TEAL / GREEN (pleasant & modern)
      0xFF00897B, // Teal
      0xFF00BFA5, // Mint Teal
      0xFF43A047, // Green
      0xFF00C853, // Neon Green (accent)

      // ORANGE / YELLOW (warm accents)
      0xFFFB8C00, // Orange
      0xFFFF7043, // Coral
      0xFFFFB300, // Amber
      0xFFFFD54F, // Soft Yellow

      // DARK / NEUTRAL (premium look)
      0xFF263238, // Dark Blue Grey
      0xFF37474F, // Blue Grey
      0xFF121212, // True Dark
      0xFF1C1C1E, // iOS Dark
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: palette.map((c) {
        final active = c == selected;
        return InkWell(
          onTap: () => onPick(c),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Color(c),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: active ? Colors.white : Colors.transparent, width: 2),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ScanResult {
  final String value;
  final CodeType codeType;
  _ScanResult(this.value, this.codeType);
}
