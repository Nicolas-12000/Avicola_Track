import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/veterinary_visits_provider.dart';

class VeterinaryVisitDetailScreen extends ConsumerWidget {
  final int visitId;

  const VeterinaryVisitDetailScreen({super.key, required this.visitId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitsState = ref.watch(veterinaryVisitsProvider);
    final matched = visitsState.visits.where((v) => v.id == visitId).toList();
    final visit = matched.isNotEmpty ? matched.first : null;

    if (visit == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle de Visita'), backgroundColor: AppColors.primary),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Detalle de la visita no disponible'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  ref.read(veterinaryVisitsProvider.notifier).loadVisits();
                },
                child: const Text('Recargar visitas'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Visita'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event, color: AppColors.primary, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${DateFormat('d MMM yyyy', 'es').format(visit.visitDate)} • ${DateFormat('HH:mm').format(visit.visitDate)}',
                    style: AppTextStyles.textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Tipo: ${visit.visitType}', style: AppTextStyles.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text('Estado: ${visit.status}', style: AppTextStyles.textTheme.bodyMedium),
            const SizedBox(height: 12),
            if (visit.reason != null && visit.reason!.isNotEmpty) ...[
              Text('Motivo', style: AppTextStyles.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(visit.reason!, style: AppTextStyles.textTheme.bodyMedium),
              const SizedBox(height: 12),
            ],
            if (visit.flockIds.isNotEmpty) ...[
              Text('Lotes', style: AppTextStyles.textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: visit.flockIds.map((id) => Chip(label: Text('Lote #$id'))).toList(),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Volver'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
