import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/veterinary_visits_provider.dart';
import '../providers/veterinary_other_providers.dart';

class VeterinaryDashboardScreen extends ConsumerStatefulWidget {
  const VeterinaryDashboardScreen({super.key});

  @override
  ConsumerState<VeterinaryDashboardScreen> createState() =>
      _VeterinaryDashboardScreenState();
}

class _VeterinaryDashboardScreenState
    extends ConsumerState<VeterinaryDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await Future.wait([
      ref.read(veterinaryVisitsProvider.notifier).loadVisits(),
      ref.read(vaccinationsProvider.notifier).loadUpcomingVaccinations(7),
      ref.read(medicationsProvider.notifier).loadActiveMedications(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final visitsState = ref.watch(veterinaryVisitsProvider);
    final vaccinationsState = ref.watch(vaccinationsProvider);
    final medicationsState = ref.watch(medicationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Veterinario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => context.push('/veterinary/agenda'),
            tooltip: 'Ver Agenda',
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: visitsState.totalOverdue > 0,
              label: Text('${visitsState.totalOverdue}'),
              child: const Icon(Icons.notifications),
            ),
            onPressed: () => context.push('/alarms'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // KPIs
              _buildKPIsSection(
                visitsState,
                vaccinationsState,
                medicationsState,
              ),
              const SizedBox(height: 20),

              // Alertas Urgentes
              if (visitsState.totalOverdue > 0 ||
                  vaccinationsState.totalOverdue > 0)
                _buildUrgentAlertsSection(visitsState, vaccinationsState),

              const SizedBox(height: 20),

              // Visitas de Hoy
              _buildTodayVisitsSection(visitsState),
              const SizedBox(height: 20),

              // Vacunas Pendientes
              _buildUpcomingVaccinationsSection(vaccinationsState),
              const SizedBox(height: 20),

              // Medicamentos Activos
              _buildActiveMedicationsSection(medicationsState),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showQuickActionDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Acción Rápida'),
      ),
    );
  }

  Widget _buildKPIsSection(visitsState, vaccinationsState, medicationsState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumen de Hoy',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                'Visitas Hoy',
                '${visitsState.todayVisits.length}',
                Icons.calendar_today,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKPICard(
                'Vacunas Hoy',
                '${vaccinationsState.dueTodayVaccinations.length}',
                Icons.vaccines,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                'Pendientes',
                '${visitsState.totalScheduled}',
                Icons.pending_actions,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKPICard(
                'Emergencias',
                '${visitsState.totalEmergency}',
                Icons.emergency,
                Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrgentAlertsSection(visitsState, vaccinationsState) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Text(
                  'Alertas Urgentes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (visitsState.totalOverdue > 0)
              ListTile(
                leading: const Icon(Icons.event_busy, color: Colors.red),
                title: Text('${visitsState.totalOverdue} visitas atrasadas'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => context.push('/alarms'),
              ),
            if (vaccinationsState.totalOverdue > 0)
              ListTile(
                leading: const Icon(Icons.vaccines, color: Colors.red),
                title: Text(
                  '${vaccinationsState.totalOverdue} vacunas atrasadas',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => context.push('/alarms'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayVisitsSection(visitsState) {
    if (visitsState.todayVisits.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.check_circle, size: 48, color: Colors.green.shade300),
              const SizedBox(height: 8),
              const Text('No hay visitas programadas para hoy'),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Visitas de Hoy',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...visitsState.todayVisits.map(
          (visit) => Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: visit.isEmergency ? Colors.red : Colors.blue,
                child: Icon(
                  visit.isEmergency ? Icons.emergency : Icons.event,
                  color: Colors.white,
                ),
              ),
              title: Text('Lote #${visit.flockId}'),
              subtitle: Text(visit.visitType),
              trailing: ElevatedButton(
                onPressed: () => context.push('/veterinary/visits/${visit.id}'),
                child: const Text('Iniciar'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingVaccinationsSection(vaccinationsState) {
    if (vaccinationsState.dueSoonVaccinations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vacunas Próximas (7 días)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...vaccinationsState.dueSoonVaccinations
            .take(3)
            .map(
              (vac) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: vac.isDueToday
                        ? Colors.orange
                        : Colors.green,
                    child: const Icon(Icons.vaccines, color: Colors.white),
                  ),
                  title: Text(vac.vaccineName),
                  subtitle: Text(
                    'Lote #${vac.flockId} - ${vac.scheduledDate.toString().substring(0, 10)}',
                  ),
                  trailing: vac.isDueToday
                      ? const Chip(
                          label: Text('Hoy'),
                          backgroundColor: Colors.orange,
                        )
                      : null,
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildActiveMedicationsSection(medicationsState) {
    if (medicationsState.activeMedications.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Medicamentos Activos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => context.push('/alarms'),
              child: const Text('Ver todos'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...medicationsState.activeMedications
            .take(3)
            .map(
              (med) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: med.isInWithdrawal
                        ? Colors.red
                        : Colors.purple,
                    child: const Icon(Icons.medication, color: Colors.white),
                  ),
                  title: Text(med.medicationName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lote #${med.flockId}'),
                      if (med.isInWithdrawal)
                        Text(
                          'En retiro: ${med.daysRemainingWithdrawal} días',
                          style: const TextStyle(color: Colors.red),
                        ),
                    ],
                  ),
                  trailing: med.isDueToday
                      ? const Chip(
                          label: Text('Aplicar hoy'),
                          backgroundColor: Colors.orange,
                        )
                      : null,
                ),
              ),
            ),
      ],
    );
  }

  void _showQuickActionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Acción Rápida'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Registrar Visita'),
              onTap: () {
                Navigator.pop(context);
                context.push('/veterinary/agenda');
              },
            ),
            ListTile(
              leading: const Icon(Icons.vaccines),
              title: const Text('Aplicar Vacuna'),
              onTap: () {
                Navigator.pop(context);
                context.push('/veterinary/agenda');
              },
            ),
            ListTile(
              leading: const Icon(Icons.medication),
              title: const Text('Prescribir Medicamento'),
              onTap: () {
                Navigator.pop(context);
                context.push('/veterinary/agenda');
              },
            ),
            ListTile(
              leading: const Icon(Icons.checklist),
              title: const Text('Checklist Bioseguridad'),
              onTap: () {
                Navigator.pop(context);
                context.push('/veterinary/agenda');
              },
            ),
          ],
        ),
      ),
    );
  }
}
