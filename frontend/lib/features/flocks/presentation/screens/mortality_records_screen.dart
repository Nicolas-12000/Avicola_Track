import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/providers/flocks_provider.dart';

class MortalityRecordsScreen extends ConsumerStatefulWidget {
  final int flockId;
  const MortalityRecordsScreen({super.key, required this.flockId});

  @override
  ConsumerState<MortalityRecordsScreen> createState() => _MortalityRecordsScreenState();
}

class _MortalityRecordsScreenState extends ConsumerState<MortalityRecordsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(flocksProvider.notifier).loadMortalityRecords(widget.flockId));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(flocksProvider);
    final records = state.mortalityRecords;

    return Scaffold(
      appBar: AppBar(title: Text('Registros de Mortalidad - Lote #${widget.flockId}')),
      body: records.isEmpty
          ? const Center(child: Text('No hay registros de mortalidad'))
          : ListView.builder(
              itemCount: records.length,
              itemBuilder: (context, index) {
                final r = records[index];
                return ListTile(
                  title: Text('${r.quantity} aves'),
                  subtitle: Text('Causa: ${r.cause} - Fecha: ${r.recordDate.toIso8601String().split('T')[0]}'),
                );
              },
            ),
    );
  }
}
