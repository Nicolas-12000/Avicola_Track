import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../data/models/veterinary_visit_model.dart';
import '../providers/veterinary_visits_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class VeterinaryAgendaScreen extends ConsumerStatefulWidget {
  const VeterinaryAgendaScreen({super.key});

  @override
  ConsumerState<VeterinaryAgendaScreen> createState() =>
      _VeterinaryAgendaScreenState();
}

class _VeterinaryAgendaScreenState
    extends ConsumerState<VeterinaryAgendaScreen> {
  DateTime _selectedDate = DateTime.now();
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Read optional farm id from provider (set by the menu) so the agenda
      // can show visits scoped to a specific farm when navigated from Farm Admin.
      final farmId = ref.read(veterinaryAgendaFarmProvider);
      ref.read(veterinaryVisitsProvider.notifier).loadVisits(farmId: farmId);
      // clear the temporary selection to avoid reusing it accidentally
      ref.read(veterinaryAgendaFarmProvider.notifier).state = null;
    });
  }

  void _selectDate(DateTime date) {
    setState(() => _selectedDate = date);
  }

  void _previousWeek() {
    setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 7)));
  }

  void _nextWeek() {
    setState(() => _selectedDate = _selectedDate.add(const Duration(days: 7)));
  }

  void _goToToday() {
    setState(() => _selectedDate = DateTime.now());
  }

  List<VeterinaryVisitModel> _getVisitsForDate(
    DateTime date,
    List<VeterinaryVisitModel> allVisits,
  ) {
    return allVisits.where((visit) {
      final visitDate = visit.visitDate;
      final isSameDay = visitDate.year == date.year &&
          visitDate.month == date.month &&
          visitDate.day == date.day;
      
      if (!isSameDay) return false;
      
      if (_filterStatus == 'all') return true;
      return visit.status == _filterStatus;
    }).toList()
      ..sort((a, b) => a.visitDate.compareTo(b.visitDate));
  }

  @override
  Widget build(BuildContext context) {
    final visitsState = ref.watch(veterinaryVisitsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda Veterinaria'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.medical_services),
            tooltip: 'Programar visita veterinaria',
            onPressed: () {
              final authState = ref.read(authProvider);
              final assignedFarm = authState.user?.assignedFarm;
              if (assignedFarm != null) {
                context.push('/farms/$assignedFarm/schedule-visit');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No tiene granja asignada')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Hoy',
            onPressed: _goToToday,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(veterinaryVisitsProvider.notifier).loadVisits();
            },
          ),
        ],
      ),
      body: visitsState.isLoading
          ? const LoadingWidget()
          : Column(
              children: [
                _buildWeekSelector(),
                _buildDateSelector(visitsState.visits),
                _buildStatusFilter(),
                Expanded(
                  child: _buildVisitsList(
                    _getVisitsForDate(_selectedDate, visitsState.visits),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildWeekSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _previousWeek,
          ),
          Expanded(
            child: Center(
              child: Text(
                DateFormat('MMMM yyyy', 'es').format(_selectedDate),
                style: AppTextStyles.textTheme.titleLarge,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _nextWeek,
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(List<VeterinaryVisitModel> allVisits) {
    final weekStart = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - 1),
    );

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemBuilder: (context, index) {
          final date = weekStart.add(Duration(days: index));
          final isSelected = date.day == _selectedDate.day &&
              date.month == _selectedDate.month &&
              date.year == _selectedDate.year;
          final isToday = date.day == DateTime.now().day &&
              date.month == DateTime.now().month &&
              date.year == DateTime.now().year;
          
          final visitsCount = allVisits.where((v) {
            return v.visitDate.year == date.year &&
                v.visitDate.month == date.month &&
                v.visitDate.day == date.day;
          }).length;

          return GestureDetector(
            onTap: () => _selectDate(date),
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : isToday
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isToday ? AppColors.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E', 'es').format(date).toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (visitsCount > 0) ...[
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$visitsCount',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? AppColors.primary
                              : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Todas', 'all'),
            const SizedBox(width: 8),
            _buildFilterChip('Programadas', 'scheduled'),
            const SizedBox(width: 8),
            _buildFilterChip('En Progreso', 'in_progress'),
            const SizedBox(width: 8),
            _buildFilterChip('Completadas', 'completed'),
            const SizedBox(width: 8),
            _buildFilterChip('Canceladas', 'cancelled'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String status) {
    final isSelected = _filterStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filterStatus = status);
      },
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildVisitsList(List<VeterinaryVisitModel> visits) {
    if (visits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay visitas programadas',
              style: AppTextStyles.textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            Text(
              'para ${DateFormat('d \'de\' MMMM', 'es').format(_selectedDate)}',
              style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: visits.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final visit = visits[index];
        return _buildVisitCard(visit);
      },
    );
  }

  Widget _buildVisitCard(VeterinaryVisitModel visit) {
    Color statusColor;
    IconData statusIcon;
    
    switch (visit.status) {
      case 'scheduled':
        statusColor = Colors.blue;
        statusIcon = Icons.schedule;
        break;
      case 'in_progress':
        statusColor = Colors.orange;
        statusIcon = Icons.timelapse;
        break;
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: () {
          context.push('/veterinary/visits/${visit.id}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(visit.visitDate),
                          style: AppTextStyles.textTheme.titleLarge?.copyWith(
                            color: statusColor,
                          ),
                        ),
                        Text(
                          _getVisitTypeLabel(visit.visitType),
                          style: AppTextStyles.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(
                      '${visit.expectedDurationDays} día${visit.expectedDurationDays > 1 ? 's' : ''}',
                    ),
                    backgroundColor: Colors.grey[200],
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              if (visit.reason != null && visit.reason!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.description, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          visit.reason!,
                          style: AppTextStyles.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (visit.flockIds.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: visit.flockIds.map((id) {
                    return Chip(
                      label: Text('Lote #$id'),
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      labelStyle: const TextStyle(fontSize: 11),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getVisitTypeLabel(String type) {
    switch (type) {
      case 'routine':
        return 'Rutina';
      case 'emergency':
        return 'Emergencia';
      case 'vaccination':
        return 'Vacunación';
      case 'treatment':
        return 'Tratamiento';
      default:
        return type;
    }
  }
}
