import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/providers/flocks_provider.dart';

class WeightRecordsScreen extends ConsumerStatefulWidget {
  final int flockId;
  const WeightRecordsScreen({super.key, required this.flockId});

  @override
  ConsumerState<WeightRecordsScreen> createState() => _WeightRecordsScreenState();
}

class _WeightRecordsScreenState extends ConsumerState<WeightRecordsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(flocksProvider.notifier).loadWeightRecords(widget.flockId));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(flocksProvider);
    final records = state.weightRecords;

    return Scaffold(
      appBar: AppBar(title: Text('Registros de Peso - Lote #${widget.flockId}')),
      body: records.isEmpty
          ? const Center(child: Text('No hay registros de peso'))
          : ListView.builder(
              itemCount: records.length,
              itemBuilder: (context, index) {
                final r = records[index];
                return ListTile(
                  title: Text('${r.averageWeight.toStringAsFixed(1)} g'),
                  subtitle: Text('Muestra: ${r.sampleSize} - Fecha: ${r.recordDate.toIso8601String().split('T')[0]}'),
                );
              },
            ),
    );
  }
}
