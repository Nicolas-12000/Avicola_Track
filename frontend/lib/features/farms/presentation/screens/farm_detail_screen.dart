import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../data/models/farm_model.dart';
import '../../../../data/models/user_model.dart';
import '../providers/farms_provider.dart';
import '../../../users/presentation/providers/users_provider.dart';

class FarmDetailScreen extends ConsumerStatefulWidget {
  final int farmId;

  const FarmDetailScreen({super.key, required this.farmId});

  @override
  ConsumerState<FarmDetailScreen> createState() => _FarmDetailScreenState();
}

class _FarmDetailScreenState extends ConsumerState<FarmDetailScreen> {
  FarmModel? _farm;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _locationCtrl;
  int? _selectedManagerId;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _locationCtrl = TextEditingController();

    // Pre cargar managers
    Future.microtask(() {
      ref.read(usersProvider.notifier).loadUsers();
      _loadFarm();
    });
  }

  Future<void> _loadFarm() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final repo = ref.read(farmRepositoryProvider);
    final result = await repo.getFarm(widget.farmId);

    if (result.failure != null) {
      setState(() {
        _isLoading = false;
        _error = result.failure!.message;
      });
      return;
    }

    final farm = result.farm!;
    setState(() {
      _farm = farm;
      _nameCtrl.text = farm.name;
      _locationCtrl.text = farm.location;
      _selectedManagerId = farm.farmManagerId;
      _isLoading = false;
    });
  }

  Future<void> _saveChanges() async {
    if (_farm == null) return;
    setState(() => _isSaving = true);

    final notifier = ref.read(farmsProvider.notifier);
    final ok = await notifier.updateFarm(
      id: _farm!.id,
      name: _nameCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      farmManager: _selectedManagerId,
    );

    setState(() => _isSaving = false);

    if (!ok) {
      final err = ref.read(farmsProvider).error ?? 'No se pudo actualizar la granja';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err)),
        );
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Granja actualizada')),
      );
    }

    // Refrescar detalle con datos actuales
    await _loadFarm();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final managers = _getManagers();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de granja'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.medical_services),
            tooltip: 'Programar visita veterinaria',
            onPressed: () {
              if (_farm != null) {
                context.push('/farms/${_farm!.id}/schedule-visit');
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFarm,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _error != null
              ? _buildErrorState()
              : _buildContent(managers),
      bottomNavigationBar: _isLoading || _error != null
          ? null
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Guardando...' : 'Guardar cambios'),
              ),
            ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(_error ?? 'Error', style: AppTextStyles.textTheme.titleMedium),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loadFarm,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<UserModel> managers) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(),
          const SizedBox(height: 16),
          _buildEditForm(managers),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    final farm = _farm!;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.cardShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(farm.name, style: AppTextStyles.textTheme.titleLarge),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.place, size: 18, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  farm.location,
                  style: AppTextStyles.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _statChip('Capacidad total', farm.totalCapacity.toString()),
              _statChip('Galpones activos', farm.activeSheds.toString()),
              _statChip('Galpones', (farm.shedsCount ?? 0).toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value) {
    return Chip(
      backgroundColor: AppColors.primary.withValues(alpha: 0.08),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppTextStyles.textTheme.bodyMedium),
          const SizedBox(width: 8),
          Text(value, style: AppTextStyles.textTheme.titleMedium),
        ],
      ),
    );
  }

  Widget _buildEditForm(List<UserModel> managers) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.cardShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Editar', style: AppTextStyles.textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              prefixIcon: Icon(Icons.business),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _locationCtrl,
            decoration: const InputDecoration(
              labelText: 'Ubicación',
              prefixIcon: Icon(Icons.place),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            value: managers.any((m) => m.id == _selectedManagerId) ? _selectedManagerId : null,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Administrador de granja (opcional)',
              prefixIcon: Icon(Icons.admin_panel_settings),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Sin asignar'),
              ),
              ...managers.map(
                (u) => DropdownMenuItem<int?>(
                  value: u.id,
                  child: Text(u.fullName.isNotEmpty ? u.fullName : (u.username ?? '')),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() => _selectedManagerId = value);
            },
          ),
        ],
      ),
    );
  }

  List<UserModel> _getManagers() {
    final usersState = ref.watch(usersProvider);
    return usersState.users
        .where((u) => u.role == 'Administrador de Granja' || u.role == 'Administrador Sistema')
        .toList();
  }
}