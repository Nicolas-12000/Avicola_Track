import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/farm_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../users/presentation/providers/users_provider.dart';
import '../../../flocks/presentation/providers/flocks_provider.dart';
import '../../../veterinary/presentation/providers/veterinary_visits_provider.dart';
import '../providers/farms_provider.dart';

class ScheduleVeterinaryVisitScreen extends ConsumerStatefulWidget {
  final int farmId;

  const ScheduleVeterinaryVisitScreen({super.key, required this.farmId});

  @override
  ConsumerState<ScheduleVeterinaryVisitScreen> createState() =>
      _ScheduleVeterinaryVisitScreenState();
}

class _ScheduleVeterinaryVisitScreenState
    extends ConsumerState<ScheduleVeterinaryVisitScreen> {
  final _formKey = GlobalKey<FormState>();
  
  int? _selectedVeterinarianId;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _expectedDurationDays = 1;
  String _visitType = 'routine';
  final _reasonController = TextEditingController();
  final Set<int> _selectedFlockIds = {};
  bool _isSaving = false;
  FarmModel? _farm;

  final List<Map<String, String>> _visitTypes = [
    {'value': 'routine', 'label': 'Rutina'},
    {'value': 'emergency', 'label': 'Emergencia'},
    {'value': 'vaccination', 'label': 'Vacunación'},
    {'value': 'treatment', 'label': 'Tratamiento'},
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(usersProvider.notifier).loadUsers();
      ref.read(flocksProvider.notifier).loadFlocks(farmId: widget.farmId);
      _loadFarmDetails();
    });
  }

  Future<void> _loadFarmDetails() async {
    final repo = ref.read(farmRepositoryProvider);
    final result = await repo.getFarm(widget.farmId);
    if (result.farm != null) {
      setState(() => _farm = result.farm);
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _saveVisit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVeterinarianId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un veterinario')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final visitDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final data = {
      'farm': widget.farmId,
      'veterinarian': _selectedVeterinarianId,
      'flocks': _selectedFlockIds.toList(),
      'visit_date': visitDateTime.toIso8601String(),
      'expected_duration_days': _expectedDurationDays,
      'visit_type': _visitType,
      'reason': _reasonController.text.trim(),
      'status': 'scheduled',
    };

    final success = await ref
        .read(veterinaryVisitsProvider.notifier)
        .createVisit(data);

    setState(() => _isSaving = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cita veterinaria programada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } else {
      final error = ref.read(veterinaryVisitsProvider).error ??
          'No se pudo programar la cita';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersState = ref.watch(usersProvider);
    final flocksState = ref.watch(flocksProvider);
    
    final veterinarians = usersState.users
        .where((u) => u.role == 'Veterinario')
        .toList();

    final farmFlocks = flocksState.flocks
        .where((f) => f.farmId == widget.farmId && f.isActive)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Programar Visita Veterinaria'),
        backgroundColor: AppColors.primary,
      ),
      body: usersState.isLoading || flocksState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFarmInfo(),
                    const SizedBox(height: 24),
                    _buildVeterinarianSelector(veterinarians),
                    const SizedBox(height: 16),
                    _buildDateTimeSelector(),
                    const SizedBox(height: 16),
                    _buildDurationSelector(),
                    const SizedBox(height: 16),
                    _buildVisitTypeSelector(),
                    const SizedBox(height: 16),
                    _buildReasonField(),
                    const SizedBox(height: 16),
                    _buildFlockSelector(farmFlocks),
                    const SizedBox(height: 24),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFarmInfo() {
    if (_farm == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.business, color: AppColors.primary, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _farm!.name,
                  style: AppTextStyles.textTheme.titleLarge,
                ),
                Text(
                  _farm!.location,
                  style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVeterinarianSelector(List<UserModel> veterinarians) {
    return DropdownButtonFormField<int>(
      value: _selectedVeterinarianId,
      decoration: const InputDecoration(
        labelText: 'Veterinario *',
        prefixIcon: Icon(Icons.medical_services),
        border: OutlineInputBorder(),
      ),
      items: veterinarians.map((vet) {
        return DropdownMenuItem<int>(
          value: vet.id,
          child: Text(vet.fullName.isNotEmpty ? vet.fullName : vet.username ?? ''),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedVeterinarianId = value),
      validator: (value) => value == null ? 'Selecciona un veterinario' : null,
    );
  }

  Widget _buildDateTimeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fecha y Hora de la Visita *', style: AppTextStyles.textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: _selectTime,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.access_time),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(_selectedTime.format(context)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDurationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Duración Estimada *', style: AppTextStyles.textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _expectedDurationDays.toDouble(),
                min: 1,
                max: 7,
                divisions: 6,
                label: '$_expectedDurationDays día${_expectedDurationDays > 1 ? 's' : ''}',
                onChanged: (value) => setState(() => _expectedDurationDays = value.toInt()),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$_expectedDurationDays día${_expectedDurationDays > 1 ? 's' : ''}',
                style: AppTextStyles.textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVisitTypeSelector() {
    return DropdownButtonFormField<String>(
      value: _visitType,
      decoration: const InputDecoration(
        labelText: 'Tipo de Visita *',
        prefixIcon: Icon(Icons.category),
        border: OutlineInputBorder(),
      ),
      items: _visitTypes.map((type) {
        return DropdownMenuItem<String>(
          value: type['value'],
          child: Text(type['label']!),
        );
      }).toList(),
      onChanged: (value) => setState(() => _visitType = value!),
    );
  }

  Widget _buildReasonField() {
    return TextFormField(
      controller: _reasonController,
      decoration: const InputDecoration(
        labelText: 'Motivo de la Visita',
        prefixIcon: Icon(Icons.description),
        border: OutlineInputBorder(),
        hintText: 'Describe el motivo de la visita...',
      ),
      maxLines: 3,
      validator: (value) {
        if (_visitType == 'emergency' && (value == null || value.trim().isEmpty)) {
          return 'El motivo es obligatorio para visitas de emergencia';
        }
        return null;
      },
    );
  }

  Widget _buildFlockSelector(List flocks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Lotes a Revisar (Opcional)', style: AppTextStyles.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Selecciona los lotes que se revisarán durante la visita',
          style: AppTextStyles.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 12),
        if (flocks.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('No hay lotes activos en esta granja'),
          )
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: flocks.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final flock = flocks[index];
                final isSelected = _selectedFlockIds.contains(flock.id);
                
                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _selectedFlockIds.add(flock.id);
                      } else {
                        _selectedFlockIds.remove(flock.id);
                      }
                    });
                  },
                  title: Text('Lote #${flock.id} - ${flock.breed}'),
                  subtitle: Text(
                    'Edad: ${flock.ageInWeeks} sem - ${flock.currentQuantity} aves',
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _saveVisit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.check_circle),
        label: Text(
          _isSaving ? 'Programando...' : 'Programar Visita',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
