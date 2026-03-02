import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/notifications_provider.dart';
import '../../../../data/models/alarm_model.dart';
import '../../../alarms/presentation/providers/alarms_provider.dart';
import '../../../farms/presentation/providers/farms_provider.dart';

/// Pantalla unificada de Alertas — combina alarmas y notificaciones en un solo lugar.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedSeverity;
  int? _selectedFarmId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAlarms();
      ref.read(alarmsProvider.notifier).loadAlarmStats(farmId: _selectedFarmId);
      ref.read(farmsProvider.notifier).loadFarms();
      ref.read(notificationsProvider.notifier).fetchRecentNotifications();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {}); // rebuild to hide/show farm filter & stats on notification tab
      if (_tabController.index == 0) {
        _loadAlarms(isResolved: false);
      } else if (_tabController.index == 1) {
        _loadAlarms(isResolved: true);
      }
    }
  }

  void _loadAlarms({bool? isResolved}) {
    ref.read(alarmsProvider.notifier).loadAlarms(
          farmId: _selectedFarmId,
          severity: _selectedSeverity,
          isResolved: isResolved,
        );
  }

  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final alarmsState = ref.watch(alarmsProvider);
    final farmsState = ref.watch(farmsProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final isOnAlarmsTab = _tabController.index < 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertas'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            // Activas tab — badge with unresolved count
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Activas'),
                  if (alarmsState.unresolvedCount > 0) ...[
                    const SizedBox(width: 6),
                    _badge('${alarmsState.unresolvedCount}', Colors.red),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Resueltas'),
            // Notificaciones tab — badge with unread count
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Notificaciones'),
                  if (unreadCount > 0) ...[
                    const SizedBox(width: 6),
                    _badge('$unreadCount', Colors.deepPurple),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Severity filter only on alarm tabs
          if (isOnAlarmsTab)
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list),
              onSelected: (value) {
                setState(() {
                  _selectedSeverity = value == 'all' ? null : value;
                });
                _loadAlarms(isResolved: _tabController.index == 1);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'all', child: Text('Todas')),
                PopupMenuItem(value: 'critical', child: Text('Críticas')),
                PopupMenuItem(value: 'high', child: Text('Altas')),
                PopupMenuItem(value: 'medium', child: Text('Medias')),
                PopupMenuItem(value: 'low', child: Text('Bajas')),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Farm filter + stats only on alarm tabs
          if (isOnAlarmsTab) ...[
            _buildFarmFilter(farmsState),
            if (alarmsState.stats != null)
              _buildStatsCard(alarmsState.stats!),
          ],
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAlarmsList(alarmsState, isResolved: false),
                _buildAlarmsList(alarmsState, isResolved: true),
                _buildNotificationsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shared widgets ─────────────────────────────────────────────────────

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ─── Farm filter ────────────────────────────────────────────────────────

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
                value: _selectedFarmId,
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
                  setState(() => _selectedFarmId = farmId);
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

  // ─── Stats card ─────────────────────────────────────────────────────────

  Widget _buildStatsCard(Map<String, dynamic> stats) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statItem('Críticas', stats['critical']?.toString() ?? '0', Colors.red),
            _statItem('Altas', stats['high']?.toString() ?? '0', Colors.orange),
            _statItem('Medias', stats['medium']?.toString() ?? '0', Colors.amber),
            _statItem('Bajas', stats['low']?.toString() ?? '0', Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
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

  // ─── Alarms list (Activas / Resueltas) ────────────────────────────────

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
              Icon(Icons.cloud_off_outlined, size: 64, color: Colors.grey[400]),
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
              isResolved ? 'No hay alarmas resueltas' : 'No hay alarmas activas',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadAlarms(isResolved: isResolved),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          final s = ref.read(alarmsProvider);
          if (notification is ScrollEndNotification &&
              notification.metrics.extentAfter < 200 &&
              !s.isLoadingMore &&
              s.hasMoreData) {
            ref.read(alarmsProvider.notifier).loadMoreAlarms();
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount:
              alarms.length + (ref.watch(alarmsProvider).isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == alarms.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return _buildAlarmCard(alarms[index]);
          },
        ),
      ),
    );
  }

  // ─── Alarm card ─────────────────────────────────────────────────────────

  Widget _buildAlarmCard(AlarmModel alarm) {
    final color = _severityColor(alarm.severity);
    final icon = _severityIcon(alarm.severity);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: alarm.isResolved ? 1 : 3,
      child: InkWell(
        onTap: () => _showAlarmDetails(alarm),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border(left: BorderSide(color: color, width: 4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(icon, color: color, size: 24),
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
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _severityText(alarm.severity),
                        style: TextStyle(
                          color: color,
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

                // Type & date
                Row(
                  children: [
                    Icon(Icons.category, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(alarm.alarmType,
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(_fmtDate(alarm.createdAt),
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),

                // Resolution info
                if (alarm.isResolved && alarm.resolvedAt != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.check_circle,
                          size: 16, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        'Resuelta el ${_fmtDate(alarm.resolvedAt!)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],

                // Actions (only for unresolved)
                if (!alarm.isResolved) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _showResolveDialog(alarm),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Resolver'),
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.green),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _showEscalateDialog(alarm),
                        icon: const Icon(Icons.arrow_upward, size: 18),
                        label: const Text('Escalar'),
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.orange),
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

  // ─── Notifications tab ──────────────────────────────────────────────────

  Widget _buildNotificationsTab() {
    final state = ref.watch(notificationsProvider);
    final notifications = state.notifications;

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(notificationsProvider.notifier).fetchRecentNotifications();
      },
      child: notifications.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 120),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.notifications_off,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No hay notificaciones recientes',
                          style: TextStyle(fontSize: 18, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final n = notifications[index];
                final details = n.alarmDetails ?? {};
                final isResolved = details['status']?.toString().toUpperCase() ==
                    'RESOLVED';
                final resolvedBy = details['resolved_by'] as String?;
                final resolvedAt = details['resolved_at'] as String?;
                final priority = details['priority']?.toString().toUpperCase();

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        _priorityColor(priority).withValues(alpha: 0.15),
                    child: Icon(
                      n.alarmId != null
                          ? Icons.notification_important
                          : Icons.notifications,
                      color: _priorityColor(priority),
                    ),
                  ),
                  title: Text(n.title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(n.body),
                      if (n.alarmId != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              isResolved
                                  ? Icons.check_circle
                                  : Icons.warning_amber_rounded,
                              size: 14,
                              color:
                                  isResolved ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isResolved ? 'Resuelta' : 'Activa',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color:
                                    isResolved ? Colors.green : Colors.orange,
                              ),
                            ),
                            if (isResolved && resolvedBy != null) ...[
                              const SizedBox(width: 8),
                              Text('por $resolvedBy',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                            ],
                          ],
                        ),
                        if (isResolved && resolvedAt != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text('Resuelta el: $resolvedAt',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                          ),
                      ],
                    ],
                  ),
                  trailing: Text(
                    _fmtDate(n.createdAt.toLocal()),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  onTap: () {
                    if (n.alarmId != null) {
                      // Navigate to the Active alarms tab
                      _tabController.animateTo(0);
                    }
                  },
                );
              },
            ),
    );
  }

  // ─── Dialogs ────────────────────────────────────────────────────────────

  void _showAlarmDetails(AlarmModel alarm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(alarm.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Tipo', alarm.alarmType),
              _detailRow('Severidad', _severityText(alarm.severity)),
              _detailRow('Descripción', alarm.description),
              _detailRow('Fecha', _fmtDate(alarm.createdAt)),
              if (alarm.isResolved) ...[
                const Divider(),
                _detailRow(
                  'Resuelta el',
                  alarm.resolvedAt != null
                      ? _fmtDate(alarm.resolvedAt!)
                      : '-',
                ),
                if (alarm.resolutionNotes != null)
                  _detailRow('Notas', alarm.resolutionNotes!),
              ],
            ],
          ),
        ),
        actions: [
          if (alarm.farmId != 0 && alarm.alarmType.isNotEmpty)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showConfigDialog(alarm);
              },
              child: const Text('Editar límites'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showConfigDialog(AlarmModel alarm) {
    final formKey = GlobalKey<FormState>();
    final thresholdCtrl = TextEditingController();
    final criticalCtrl = TextEditingController();
    final evalCtrl = TextEditingController(text: '24');
    final consecutiveCtrl = TextEditingController(text: '1');
    bool notifyFarm = true;
    bool notifyVet = true;
    bool notifyGalponero = false;
    bool isActive = true;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Configurar límites - ${alarm.alarmType}'),
        content: StatefulBuilder(
          builder: (ctx, setDialogState) {
            return SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: thresholdCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration:
                          const InputDecoration(labelText: 'Threshold (valor)'),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: criticalCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                          labelText: 'Critical threshold (opcional)'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: evalCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Periodo evaluación (horas)'),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: consecutiveCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Ocurrencias consecutivas'),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      title: const Text('Notificar encargado de granja'),
                      value: notifyFarm,
                      onChanged: (v) =>
                          setDialogState(() => notifyFarm = v ?? true),
                    ),
                    CheckboxListTile(
                      title: const Text('Notificar veterinario'),
                      value: notifyVet,
                      onChanged: (v) =>
                          setDialogState(() => notifyVet = v ?? true),
                    ),
                    CheckboxListTile(
                      title: const Text('Notificar galponeros'),
                      value: notifyGalponero,
                      onChanged: (v) =>
                          setDialogState(() => notifyGalponero = v ?? false),
                    ),
                    SwitchListTile(
                      title: const Text('Activo'),
                      value: isActive,
                      onChanged: (v) =>
                          setDialogState(() => isActive = v),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final ds = ref.read(alarmDataSourceProvider);
              final payload = {
                'alarm_type': alarm.alarmType,
                'farm': alarm.farmId,
                'threshold_value': double.parse(thresholdCtrl.text),
                'critical_threshold': criticalCtrl.text.isEmpty
                    ? null
                    : double.parse(criticalCtrl.text),
                'evaluation_period_hours': int.parse(evalCtrl.text),
                'consecutive_occurrences': int.parse(consecutiveCtrl.text),
                'notify_farm_manager': notifyFarm,
                'notify_veterinarian': notifyVet,
                'notify_galponeros': notifyGalponero,
                'is_active': isActive,
              };
              try {
                final configs = await ds.getAlarmConfigs(
                    farmId: alarm.farmId, alarmType: alarm.alarmType);
                if (configs.isNotEmpty) {
                  await ds.updateAlarmConfig(
                      configs.first['id'] as int, payload);
                } else {
                  await ds.createAlarmConfig(payload);
                }
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Configuración guardada')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al guardar: $e')),
                  );
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showResolveDialog(AlarmModel alarm) {
    final formKey = GlobalKey<FormState>();
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolver Alarma'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('¿Resolver "${alarm.title}"?'),
              const SizedBox(height: 16),
              TextFormField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notas de resolución',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                ref.read(alarmsProvider.notifier).resolveAlarm(
                      id: alarm.id,
                      resolutionNotes: notesCtrl.text,
                    );
                Navigator.pop(ctx);
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
      builder: (ctx) => AlertDialog(
        title: const Text('Escalar Alarma'),
        content: Text('¿Escalar "${alarm.title}" a mayor prioridad?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(alarmsProvider.notifier).escalateAlarm(alarm.id);
              Navigator.pop(ctx);
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
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar'),
        content: Text('¿Eliminar alarma "${alarm.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(alarmsProvider.notifier).deleteAlarm(alarm.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────────

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';

  Color _severityColor(String severity) {
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

  IconData _severityIcon(String severity) {
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

  String _severityText(String severity) {
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

  Color _priorityColor(String? priority) {
    switch (priority) {
      case 'URGENT':
        return Colors.red;
      case 'HIGH':
        return Colors.orange;
      case 'MEDIUM':
        return Colors.amber;
      case 'LOW':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
