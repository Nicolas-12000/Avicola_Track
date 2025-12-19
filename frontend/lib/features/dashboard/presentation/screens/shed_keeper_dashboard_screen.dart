import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../sheds/presentation/providers/sheds_provider.dart';
import '../../../flocks/presentation/providers/flocks_provider.dart';
import '../../../alarms/presentation/providers/alarms_provider.dart';
import 'package:go_router/go_router.dart';

class ShedKeeperDashboardScreen extends ConsumerStatefulWidget {
  const ShedKeeperDashboardScreen({super.key});

  @override
  ConsumerState<ShedKeeperDashboardScreen> createState() =>
      _ShedKeeperDashboardScreenState();
}

class _ShedKeeperDashboardScreenState
    extends ConsumerState<ShedKeeperDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  void _loadDashboardData() {
    // Load assigned sheds, flocks, and alarms
    ref.read(shedsProvider.notifier).loadSheds();
    ref.read(flocksProvider.notifier).loadFlocks();
    ref.read(alarmsProvider.notifier).loadAlarms();
  }

  @override
  Widget build(BuildContext context) {
    final shedsState = ref.watch(shedsProvider);
    final flocksState = ref.watch(flocksProvider);
    final alarmsState = ref.watch(alarmsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Dashboard'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications),
                if (alarmsState.unresolvedAlarms.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${alarmsState.unresolvedAlarms.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => context.push('/alarms'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadDashboardData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              _buildGreeting(),

              const SizedBox(height: 24),

              // Quick Actions
              _buildQuickActions(),

              const SizedBox(height: 24),

              // Pending Tasks Card
              _buildPendingTasksCard(flocksState),

              const SizedBox(height: 24),

              // Active Alarms
              if (alarmsState.unresolvedAlarms.isNotEmpty) ...[
                _buildSectionHeader(
                  'Alarmas Activas',
                  Icons.warning,
                  Colors.orange,
                ),
                const SizedBox(height: 12),
                _buildActiveAlarmsCard(alarmsState),
                const SizedBox(height: 24),
              ],

              // My Sheds
              _buildSectionHeader('Mis Galpones', Icons.home),
              const SizedBox(height: 12),
              _buildMyShedsGrid(shedsState, flocksState),

              const SizedBox(height: 24),

              // Today's Summary
              _buildSectionHeader('Resumen de Hoy', Icons.today),
              const SizedBox(height: 12),
              _buildTodaySummaryCard(flocksState),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showQuickRecordDialog(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Registro Rápido'),
      ),
    );
  }

  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    String greeting;
    IconData icon;

    if (hour < 12) {
      greeting = 'Buenos días';
      icon = Icons.wb_sunny;
    } else if (hour < 18) {
      greeting = 'Buenas tardes';
      icon = Icons.wb_sunny_outlined;
    } else {
      greeting = 'Buenas noches';
      icon = Icons.nights_stay;
    }

    return Card(
      color: AppColors.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat(
                      'EEEE, d MMMM yyyy',
                      'es',
                    ).format(DateTime.now()),
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionButton(
            'Peso',
            Icons.scale,
            Colors.blue,
            () => _navigateToWeightRecord(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionButton(
            'Mortalidad',
            Icons.trending_down,
            Colors.red,
            () => _navigateToMortalityRecord(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionButton(
            'Inventario',
            Icons.inventory,
            Colors.green,
            () => context.push('/inventory'),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingTasksCard(FlocksState flocksState) {
    final pendingTasks = _getPendingTasks(flocksState);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Tareas Pendientes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: pendingTasks.isEmpty ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${pendingTasks.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (pendingTasks.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 48,
                      color: Colors.green[300],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '¡Sin tareas pendientes!',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            else
              ...pendingTasks.map((task) => _buildTaskItem(task)),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem(Map<String, dynamic> task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(task['icon'] as IconData, color: Colors.orange, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task['title'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  task['description'] as String,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward, color: AppColors.primary),
            onPressed: () => _handleTaskAction(task),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveAlarmsCard(AlarmsState alarmsState) {
    final criticalAlarms = alarmsState.criticalAlarms.take(3).toList();

    return Card(
      child: Column(
        children: criticalAlarms.map((alarm) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: _getAlarmColor(alarm.severity),
              child: Icon(
                _getAlarmIcon(alarm.severity),
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(
              alarm.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              DateFormat('HH:mm').format(alarm.createdAt),
              style: const TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.push('/alarms'),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, [Color? color]) {
    return Row(
      children: [
        Icon(icon, color: color ?? AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildMyShedsGrid(ShedsState shedsState, FlocksState flocksState) {
    if (shedsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (shedsState.sheds.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.home_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No tienes galpones asignados',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: shedsState.sheds.length,
      itemBuilder: (context, index) {
        final shed = shedsState.sheds[index];
        final activeFlock = flocksState.activeFlocks
            .where((f) => f.shedId == shed.id)
            .firstOrNull;

        return Card(
          elevation: 3,
          child: InkWell(
            onTap: () => context.push('/sheds'),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          shed.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        shed.isOccupied
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: shed.isOccupied ? Colors.green : Colors.grey,
                        size: 20,
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (activeFlock != null) ...[
                    Text(
                      'Lote #${activeFlock.id}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${activeFlock.initialQuantity} aves',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ] else ...[
                    Text(
                      'Disponible',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'Cap: ${shed.capacity}',
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTodaySummaryCard(FlocksState flocksState) {
    final totalBirds = flocksState.activeFlocks.fold<int>(
      0,
      (sum, flock) => sum + flock.initialQuantity,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSummaryRow(
              'Lotes Activos',
              '${flocksState.activeFlocks.length}',
              Icons.pets,
            ),
            const Divider(),
            _buildSummaryRow('Total Aves', '$totalBirds', Icons.looks),
            const Divider(),
            _buildSummaryRow('Registros Hoy', '0', Icons.assignment_turned_in),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getPendingTasks(FlocksState flocksState) {
    final tasks = <Map<String, dynamic>>[];
    final now = DateTime.now();

    // Check for weight records needed (weekly)
    for (final flock in flocksState.activeFlocks) {
      final daysSinceStart = now.difference(flock.arrivalDate).inDays;
      if (daysSinceStart % 7 == 0) {
        tasks.add({
          'title': 'Registro de Peso',
          'description': 'Lote #${flock.id} - Pesaje semanal',
          'icon': Icons.scale,
          'action': 'weight',
          'flockId': flock.id,
        });
      }
    }

    return tasks;
  }

  void _handleTaskAction(Map<String, dynamic> task) {
    final action = task['action'] as String;

    switch (action) {
      case 'weight':
        _navigateToWeightRecord();
        break;
      case 'mortality':
        _navigateToMortalityRecord();
        break;
      default:
        break;
    }
  }

  void _navigateToWeightRecord() {
    context.push('/flocks');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Selecciona un lote para registrar peso'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _navigateToMortalityRecord() {
    context.push('/flocks');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Selecciona un lote para registrar mortalidad'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showQuickRecordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registro Rápido'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.scale, color: Colors.blue),
              title: const Text('Registrar Peso'),
              onTap: () {
                Navigator.of(context).pop();
                _navigateToWeightRecord();
              },
            ),
            ListTile(
              leading: const Icon(Icons.trending_down, color: Colors.red),
              title: const Text('Registrar Mortalidad'),
              onTap: () {
                Navigator.of(context).pop();
                _navigateToMortalityRecord();
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory, color: Colors.green),
              title: const Text('Consumo Inventario'),
              onTap: () {
                Navigator.of(context).pop();
                context.push('/inventory');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Color _getAlarmColor(String severity) {
    switch (severity) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow[700]!;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getAlarmIcon(String severity) {
    switch (severity) {
      case 'critical':
        return Icons.error;
      case 'high':
        return Icons.warning;
      case 'medium':
        return Icons.info;
      case 'low':
        return Icons.notification_important;
      default:
        return Icons.notifications;
    }
  }
}
