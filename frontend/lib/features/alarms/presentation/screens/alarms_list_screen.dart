import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/alarm_model.dart';
import '../providers/alarms_provider.dart';
import '../../../farms/presentation/providers/farms_provider.dart';
import '../../../../core/widgets/app_drawer.dart';

class AlarmsListScreen extends ConsumerStatefulWidget {
  final int? farmId;

  const AlarmsListScreen({this.farmId, super.key});

  @override
  ConsumerState<AlarmsListScreen> createState() => _AlarmsListScreenState();
}

class _AlarmsListScreenState extends ConsumerState<AlarmsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedSeverity;
  int? _selectedFarmId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedFarmId = widget.farmId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAlarms();
      ref.read(alarmsProvider.notifier).loadAlarmStats(farmId: _selectedFarmId);
      ref.read(farmsProvider.notifier).loadFarms();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadAlarms({bool? isResolved}) {
    ref
        .read(alarmsProvider.notifier)
        .loadAlarms(
          farmId: _selectedFarmId,
          severity: _selectedSeverity,
          isResolved: isResolved,
        );
  }

  @override
  Widget build(BuildContext context) {
    final alarmsState = ref.watch(alarmsProvider);
    final farmsState = ref.watch(farmsProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Alarmas'),
        backgroundColor: AppColors.primary,
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            _loadAlarms(isResolved: index == 1);
          },
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Activas'),
                  if (alarmsState.unresolvedCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${alarmsState.unresolvedCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Resueltas'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedSeverity = value == 'all' ? null : value;
              });
              _loadAlarms(isResolved: _tabController.index == 1);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('Todas')),
              const PopupMenuItem(value: 'critical', child: Text('Críticas')),
              const PopupMenuItem(value: 'high', child: Text('Altas')),
              const PopupMenuItem(value: 'medium', child: Text('Medias')),
              const PopupMenuItem(value: 'low', child: Text('Bajas')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Farm Filter
          _buildFarmFilter(farmsState),

          // Stats Card
          if (alarmsState.stats != null) _buildStatsCard(alarmsState.stats!),

          // Alarms List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAlarmsList(alarmsState, isResolved: false),
                _buildAlarmsList(alarmsState, isResolved: true),
              ],
            ),
          ),
        ],
      ),
      // Note: Create alarm not available in datasource
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () => _showCreateAlarmDialog(),
      //   backgroundColor: AppColors.primary,
      //   child: const Icon(Icons.add_alert),
      // ),
    );
  }

  Widget _buildFarmFilter(FarmsState farmsState) {
    if (farmsState.farms.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.filter_list, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int?>(
                initialValue: _selectedFarmId,
                decoration: const InputDecoration(
                  labelText: 'Filtrar por Granja',
                  border: InputBorder.none,
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Todas las granjas'),
                  ),
                  ...farmsState.farms.map((farm) {
                    return DropdownMenuItem<int?>(
                      value: farm.id,
                      child: Text(farm.name),
                    );
                  }),
                ],
                onChanged: (farmId) {
                  setState(() {
                    _selectedFarmId = farmId;
                  });
                  _loadAlarms(isResolved: _tabController.index == 1);
                  ref
                      .read(alarmsProvider.notifier)
                      .loadAlarmStats(farmId: farmId);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(Map<String, dynamic> stats) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              'Críticas',
              stats['critical']?.toString() ?? '0',
              Colors.red,
            ),
            _buildStatItem(
              'Altas',
              stats['high']?.toString() ?? '0',
              Colors.orange,
            ),
            _buildStatItem(
              'Medias',
              stats['medium']?.toString() ?? '0',
              Colors.amber,
            ),
            _buildStatItem(
              'Bajas',
              stats['low']?.toString() ?? '0',
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildAlarmsList(AlarmsState state, {required bool isResolved}) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Error al cargar las alarmas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.error!.contains('404') 
                    ? 'No hay datos de alarmas disponibles'
                    : 'Verifique su conexión e intente de nuevo',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => _loadAlarms(isResolved: isResolved),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final alarms = isResolved ? state.resolvedAlarms : state.unresolvedAlarms;

    if (alarms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isResolved ? Icons.check_circle_outline : Icons.notifications_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              isResolved
                  ? 'No hay alarmas resueltas'
                  : 'No hay alarmas activas',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadAlarms(isResolved: isResolved),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: alarms.length,
        itemBuilder: (context, index) => _buildAlarmCard(alarms[index]),
      ),
    );
  }

  Widget _buildAlarmCard(AlarmModel alarm) {
    final severityColor = _getSeverityColor(alarm.severity);
    final severityIcon = _getSeverityIcon(alarm.severity);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: alarm.isResolved ? 1 : 3,
      child: InkWell(
        onTap: () => _showAlarmDetails(alarm),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border(left: BorderSide(color: severityColor, width: 4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(severityIcon, color: severityColor, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        alarm.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: alarm.isResolved ? Colors.grey : Colors.black,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: severityColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getSeverityText(alarm.severity),
                        style: TextStyle(
                          color: severityColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  alarm.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: alarm.isResolved ? Colors.grey : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                // Type & Date
                Row(
                  children: [
                    Icon(Icons.category, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      alarm.alarmType,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(alarm.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),

                // Resolution info
                if (alarm.isResolved && alarm.resolvedAt != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Resuelta el ${_formatDate(alarm.resolvedAt!)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],

                // Actions
                if (!alarm.isResolved) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _showResolveDialog(alarm),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Resolver'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _showEscalateDialog(alarm),
                        icon: const Icon(Icons.arrow_upward, size: 18),
                        label: const Text('Escalar'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: Colors.red,
                        onPressed: () => _confirmDelete(alarm),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.amber;
      case 'low':
      default:
        return Colors.blue;
    }
  }

  IconData _getSeverityIcon(String severity) {
    switch (severity) {
      case 'critical':
        return Icons.error;
      case 'high':
        return Icons.warning;
      case 'medium':
        return Icons.info;
      case 'low':
      default:
        return Icons.info_outline;
    }
  }

  String _getSeverityText(String severity) {
    switch (severity) {
      case 'critical':
        return 'Crítica';
      case 'high':
        return 'Alta';
      case 'medium':
        return 'Media';
      case 'low':
      default:
        return 'Baja';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showAlarmDetails(AlarmModel alarm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(alarm.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Tipo', alarm.alarmType),
              _buildDetailRow('Severidad', _getSeverityText(alarm.severity)),
              _buildDetailRow('Descripción', alarm.description),
              _buildDetailRow('Fecha', _formatDate(alarm.createdAt)),
              if (alarm.isResolved) ...[
                const Divider(),
                _buildDetailRow(
                  'Resuelta el',
                  alarm.resolvedAt != null
                      ? _formatDate(alarm.resolvedAt!)
                      : '-',
                ),
                if (alarm.resolutionNotes != null)
                  _buildDetailRow('Notas', alarm.resolutionNotes!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  // Note: Create alarm not available in datasource
  // void _showCreateAlarmDialog() { ... }

  void _showResolveDialog(AlarmModel alarm) {
    final formKey = GlobalKey<FormState>();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolver Alarma'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('¿Resolver "${alarm.title}"?'),
              const SizedBox(height: 16),
              TextFormField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notas de resolución',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Requerido' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                ref
                    .read(alarmsProvider.notifier)
                    .resolveAlarm(
                      id: alarm.id,
                      resolutionNotes: notesController.text,
                    );
                Navigator.pop(context);
              }
            },
            child: const Text('Resolver'),
          ),
        ],
      ),
    );
  }

  void _showEscalateDialog(AlarmModel alarm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Escalar Alarma'),
        content: Text('¿Escalar "${alarm.title}" a mayor prioridad?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(alarmsProvider.notifier).escalateAlarm(alarm.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Escalar'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(AlarmModel alarm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar'),
        content: Text('¿Eliminar alarma "${alarm.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(alarmsProvider.notifier).deleteAlarm(alarm.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
