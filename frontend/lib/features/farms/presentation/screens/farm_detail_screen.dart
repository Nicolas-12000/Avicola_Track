import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../data/models/farm_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/models/shed_model.dart';
import '../providers/farms_provider.dart';
import '../../../users/presentation/providers/users_provider.dart';
import '../../../sheds/presentation/providers/sheds_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

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

    // Pre cargar managers, galponeros y galpones
    Future.microtask(() {
      ref.read(usersProvider.notifier).loadUsers();
      ref.read(shedsProvider.notifier).loadSheds(farmId: widget.farmId, force: true);
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
    final authState = ref.watch(authProvider);
    final currentUserRole = authState.user?.userRole;
    final isFarmAdmin = currentUserRole?.isFarmAdmin ?? false;
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
            : _buildContent(managers, isFarmAdmin),
        bottomNavigationBar: _isLoading || _error != null || isFarmAdmin
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

  Widget _buildContent(List<UserModel> managers, bool isFarmAdmin) {
    final shedsState = ref.watch(shedsProvider);
    final farmSheds = shedsState.sheds.where((s) => s.farm == widget.farmId).toList();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(),
          const SizedBox(height: 16),
          if (!isFarmAdmin) _buildEditForm(managers),
          const SizedBox(height: 16),
          _buildShedsSection(farmSheds),
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

  Widget _buildShedsSection(List<ShedModel> sheds) {
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
          Row(
            children: [
              Expanded(
                child: Text('Galpones y Galponeros', style: AppTextStyles.textTheme.titleMedium),
              ),
              Builder(
                builder: (context) {
                  final authState = ref.watch(authProvider);
                  final isFarmAdminLocal = authState.user?.userRole?.isFarmAdmin ?? false;
                  final assignedFarm = authState.user?.assignedFarm;
                  // Compact actions: keep add shed icon for system admins, compact assign button for farm admins
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isFarmAdminLocal)
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: AppColors.primary),
                          tooltip: 'Agregar galpón',
                          onPressed: () => context.push('/sheds'),
                        ),
                      if (isFarmAdminLocal)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: ElevatedButton.icon(
                            onPressed: assignedFarm == null ? null : () => _showAssignMultipleGalponerosDialog(),
                            icon: const Icon(Icons.person_add_alt_1, size: 18),
                            label: const Text('Asignar', style: TextStyle(fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              minimumSize: const Size(0, 36),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 2,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (sheds.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No hay galpones en esta granja'),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sheds.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final shed = sheds[index];
                return _buildShedTile(shed);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildShedTile(ShedModel shed) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: shed.assignedWorker != null
            ? AppColors.success.withValues(alpha: 0.2)
            : Colors.grey.withValues(alpha: 0.2),
        child: Icon(
          Icons.warehouse,
          color: shed.assignedWorker != null ? AppColors.success : Colors.grey,
        ),
      ),
      title: Text(shed.name, style: AppTextStyles.textTheme.titleSmall),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Capacidad: ${shed.capacity}'),
          if (shed.assignedWorkerName != null)
            Row(
              children: [
                const Icon(Icons.person, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    shed.assignedWorkerName!,
                    style: TextStyle(color: AppColors.primary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
          else
            const Text(
              'Sin galponero asignado',
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.person_add, color: AppColors.primary),
        tooltip: 'Asignar galponero',
        onPressed: () => _showAssignGalponeroDialog(shed),
      ),
    );
  }

  Future<void> _showAssignGalponeroDialog(ShedModel shed) async {
    final galponeros = await ref.read(usersProvider.notifier).getGalponeros();
    
    if (!mounted) return;
    
    int? selectedGalponeroId = shed.assignedWorker;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Asignar galponero a ${shed.name}'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (shed.assignedWorkerName != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Actual: ${shed.assignedWorkerName}'),
                        ),
                      ],
                    ),
                  ),
                DropdownButtonFormField<int?>(
                  value: galponeros.any((g) => g.id == selectedGalponeroId)
                      ? selectedGalponeroId
                      : null,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Seleccionar galponero',
                    prefixIcon: Icon(Icons.person_search),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Sin asignar'),
                    ),
                    ...galponeros.map(
                      (g) => DropdownMenuItem<int?>(
                        value: g.id,
                        child: Text(g.fullName.isNotEmpty ? g.fullName : (g.username ?? 'Sin nombre')),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedGalponeroId = value);
                  },
                ),
                if (galponeros.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'No hay galponeros registrados en el sistema.',
                      style: TextStyle(color: Colors.orange),
                    ),
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
              onPressed: () async {
                Navigator.pop(context);
                await _assignGalponero(shed, selectedGalponeroId);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _assignGalponero(ShedModel shed, int? galponeroId) async {
    await ref.read(shedsProvider.notifier).updateShed(
      id: shed.id,
      name: shed.name,
      farmId: shed.farm,
      capacity: shed.capacity,
      assignedWorkerId: galponeroId,
    );

    // Recargar galpones
    await ref.read(shedsProvider.notifier).loadSheds(farmId: widget.farmId, force: true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(galponeroId != null
              ? 'Galponero asignado correctamente'
              : 'Galponero removido del galpón'),
        ),
      );
    }
  }

  Future<void> _showAssignMultipleGalponerosDialog() async {
    final galponeros = await ref.read(usersProvider.notifier).getGalponeros();
    if (!mounted) return;

    // Initial selection: those already assigned to this farm
    final selected = <int>{
      for (final g in galponeros)
        if (g.assignedFarm == widget.farmId) g.id
    };

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Asignar galponeros a la granja'),
          content: SizedBox(
            width: double.maxFinite,
            child: galponeros.isEmpty
                ? const Text('No hay galponeros registrados en el sistema.')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: galponeros.length,
                    itemBuilder: (context, index) {
                      final g = galponeros[index];
                      final checked = selected.contains(g.id);
                      return CheckboxListTile(
                        value: checked,
                        title: Text(g.fullName.isNotEmpty ? g.fullName : (g.username ?? 'Sin nombre')),
                        subtitle: g.assignedFarm != null ? Text('Asignado a granja ${g.assignedFarm}') : null,
                        onChanged: (v) => setDialogState(() {
                          if (v == true) selected.add(g.id); else selected.remove(g.id);
                        }),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                // Apply changes: assign selected to this farm, remove others that were previously assigned
                for (final g in galponeros) {
                  final shouldBeAssigned = selected.contains(g.id);
                  final currentlyAssigned = g.assignedFarm == widget.farmId;
                  if (shouldBeAssigned && !currentlyAssigned) {
                    await ref.read(usersProvider.notifier).updateUser(id: g.id, assignedFarm: widget.farmId);
                  } else if (!shouldBeAssigned && currentlyAssigned) {
                    await ref.read(usersProvider.notifier).updateUser(id: g.id, assignedFarm: null);
                  }
                }

                // Refresh sheds and users
                await ref.read(shedsProvider.notifier).loadSheds(farmId: widget.farmId, force: true);
                await ref.read(usersProvider.notifier).loadUsers();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Asignaciones actualizadas')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}