import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../data/models/dispatch_record_model.dart';
import '../providers/daily_dispatch_provider.dart';

class DispatchRecordsScreen extends ConsumerStatefulWidget {
  final int flockId;
  final String? flockName;

  const DispatchRecordsScreen({
    super.key,
    required this.flockId,
    this.flockName,
  });

  @override
  ConsumerState<DispatchRecordsScreen> createState() => _DispatchRecordsScreenState();
}

class _DispatchRecordsScreenState extends ConsumerState<DispatchRecordsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(dispatchesProvider.notifier).loadDispatches(flockId: widget.flockId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dispatchesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.flockName != null
            ? 'Despachos - ${widget.flockName}'
            : 'Despachos / Pesas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(dispatchesProvider.notifier).loadDispatches(flockId: widget.flockId);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.local_shipping),
        label: const Text('Nuevo Despacho'),
      ),
      body: _buildBody(state, theme),
    );
  }

  Widget _buildBody(DispatchesState state, ThemeData theme) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return ErrorStateWidget(
        message: state.error!,
        onRetry: () {
          ref.read(dispatchesProvider.notifier).loadDispatches(flockId: widget.flockId);
        },
      );
    }
    if (state.items.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.local_shipping_outlined,
        title: 'No hay despachos registrados',
        subtitle: 'Toca + para registrar un despacho',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: state.items.length,
      itemBuilder: (context, index) {
        final dispatch = state.items[state.items.length - 1 - index];
        return _DispatchCard(
          dispatch: dispatch,
          onTapEdit: () => _showEditDialog(context, dispatch),
        );
      },
    );
  }

  void _showCreateDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _CreateDispatchForm(
        flockId: widget.flockId,
        onSubmit: (data) async {
          final success = await ref.read(dispatchesProvider.notifier).createDispatch(data);
          if (success && mounted) {
            Navigator.of(ctx).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Despacho registrado exitosamente')),
            );
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(ref.read(dispatchesProvider).error ?? 'Error al registrar despacho'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, DispatchRecordModel dispatch) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _EditDispatchPlantForm(
        dispatch: dispatch,
        onSubmit: (data) async {
          final success = await ref.read(dispatchesProvider.notifier).updateDispatch(dispatch.id, data);
          if (success && mounted) {
            Navigator.of(ctx).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Datos de planta actualizados')),
            );
          }
        },
      ),
    );
  }
}

class _DispatchCard extends StatelessWidget {
  final DispatchRecordModel dispatch;
  final VoidCallback? onTapEdit;

  const _DispatchCard({required this.dispatch, this.onTapEdit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('dd/MM/yyyy').format(dispatch.dispatchDate);
    final hasPlantData = dispatch.plantTotalKg != null;
    final hasSaleData = dispatch.saleTotalKg != null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        children: [
          // Header
          ListTile(
            leading: CircleAvatar(
              backgroundColor: hasPlantData
                  ? (hasSaleData ? Colors.green : Colors.orange)
                  : Colors.blue,
              child: Icon(
                hasPlantData
                    ? (hasSaleData ? Icons.check : Icons.pending)
                    : Icons.local_shipping,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text('Planilla ${dispatch.manifestNumber} - Día ${dispatch.dayNumber}'),
            subtitle: Text(dateStr),
            trailing: !hasSaleData
                ? TextButton.icon(
                    onPressed: onTapEdit,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Completar'),
                  )
                : null,
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                // Datos en Granja
                SectionHeader(title: 'EN GRANJA', color: Colors.blue.shade700),
                InfoRow('Machos / Hembras', '${dispatch.malesCount} / ${dispatch.femalesCount}'),
                InfoRow('Total pollos', '${dispatch.totalBirds}'),
                InfoRow('Peso promedio', '${dispatch.farmAvgWeight.toStringAsFixed(2)} kg'),
                InfoRow('Kilos totales', '${dispatch.farmTotalKg.toStringAsFixed(2)} kg'),

                if (hasPlantData) ...[
                  const SizedBox(height: 8),
                  SectionHeader(title: 'EN PLANTA', color: Colors.orange.shade700),
                  InfoRow('Pollos recibidos', '${dispatch.plantBirds ?? "-"}'),
                  if (dispatch.drowned > 0) InfoRow('Ahogados', '${dispatch.drowned}', isWarning: true),
                  if (dispatch.plantMissing > 0) InfoRow('Faltantes', '${dispatch.plantMissing}', isWarning: true),
                  InfoRow('Peso promedio', '${dispatch.plantAvgWeight?.toStringAsFixed(4) ?? "-"} kg'),
                  InfoRow('Kilos totales', '${dispatch.plantTotalKg?.toStringAsFixed(2) ?? "-"} kg'),
                  if (dispatch.plantShrinkageGrams != null)
                    InfoRow('Merma', '${dispatch.plantShrinkageGrams!.toStringAsFixed(2)} g/pollo',
                        isWarning: dispatch.plantShrinkageGrams! > 0),
                ],

                if (hasSaleData) ...[
                  const SizedBox(height: 8),
                  SectionHeader(title: 'VENTA', color: Colors.green.shade700),
                  InfoRow('Pollos vendidos', '${dispatch.saleBirds ?? "-"}'),
                  if (dispatch.saleDiscountKg > 0)
                    InfoRow('Descuento', '${dispatch.saleDiscountKg.toStringAsFixed(2)} kg', isWarning: true),
                  InfoRow('Kilos venta', '${dispatch.saleTotalKg?.toStringAsFixed(2) ?? "-"} kg'),
                  InfoRow('Peso promedio venta', '${dispatch.saleAvgWeight?.toStringAsFixed(4) ?? "-"} kg'),
                  if (dispatch.totalShrinkageGrams != null)
                    InfoRow('Merma total', '${dispatch.totalShrinkageGrams!.toStringAsFixed(2)} g/pollo',
                        isWarning: dispatch.totalShrinkageGrams! > 0),
                ],

                if (dispatch.observations != null && dispatch.observations!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.note, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(dispatch.observations!,
                            style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===================================================
// FORMULARIO CREAR DESPACHO (Datos en granja)
// ===================================================

class _CreateDispatchForm extends StatefulWidget {
  final int flockId;
  final Future<void> Function(Map<String, dynamic> data) onSubmit;

  const _CreateDispatchForm({required this.flockId, required this.onSubmit});

  @override
  State<_CreateDispatchForm> createState() => _CreateDispatchFormState();
}

class _CreateDispatchFormState extends State<_CreateDispatchForm> {
  final _formKey = GlobalKey<FormState>();
  DateTime _date = DateTime.now();
  bool _isSubmitting = false;

  final _manifestCtl = TextEditingController();
  final _malesCtl = TextEditingController(text: '0');
  final _femalesCtl = TextEditingController(text: '0');
  final _farmAvgWeightCtl = TextEditingController();
  final _farmTotalKgCtl = TextEditingController();
  final _observationsCtl = TextEditingController();

  @override
  void dispose() {
    _manifestCtl.dispose();
    _malesCtl.dispose();
    _femalesCtl.dispose();
    _farmAvgWeightCtl.dispose();
    _farmTotalKgCtl.dispose();
    _observationsCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_shipping),
                  const SizedBox(width: 8),
                  Text('Nuevo Despacho', style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: 16),

              // Fecha
              ListTile(
                leading: const Icon(Icons.date_range),
                title: Text('Fecha: ${DateFormat('dd/MM/yyyy').format(_date)}'),
                trailing: const Icon(Icons.edit_calendar),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context, initialDate: _date,
                    firstDate: DateTime(2020), lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
              ),
              const SizedBox(height: 8),

              TextFormField(
                controller: _manifestCtl,
                decoration: const InputDecoration(
                  labelText: 'Nº Planilla *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _malesCtl,
                      decoration: const InputDecoration(
                        labelText: 'Cant. Machos',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _femalesCtl,
                      decoration: const InputDecoration(
                        labelText: 'Cant. Hembras',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _farmAvgWeightCtl,
                      decoration: const InputDecoration(
                        labelText: 'Peso prom. granja (kg) *',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _farmTotalKgCtl,
                      decoration: const InputDecoration(
                        labelText: 'Kilos totales granja *',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _observationsCtl,
                decoration: const InputDecoration(
                  labelText: 'Observaciones',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              SubmitButton(
                isLoading: _isSubmitting,
                label: 'Registrar Despacho',
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final males = int.tryParse(_malesCtl.text) ?? 0;
    final females = int.tryParse(_femalesCtl.text) ?? 0;

    final data = {
      'flock': widget.flockId,
      'dispatch_date': _date.toIso8601String().split('T')[0],
      'manifest_number': _manifestCtl.text,
      'males_count': males,
      'females_count': females,
      'total_birds': males + females,
      'farm_avg_weight': double.tryParse(_farmAvgWeightCtl.text) ?? 0,
      'farm_total_kg': double.tryParse(_farmTotalKgCtl.text) ?? 0,
      'observations': _observationsCtl.text,
    };

    await widget.onSubmit(data);
    if (mounted) setState(() => _isSubmitting = false);
  }
}

// ===================================================
// FORMULARIO EDITAR DATOS PLANTA / VENTA
// ===================================================

class _EditDispatchPlantForm extends StatefulWidget {
  final DispatchRecordModel dispatch;
  final Future<void> Function(Map<String, dynamic> data) onSubmit;

  const _EditDispatchPlantForm({required this.dispatch, required this.onSubmit});

  @override
  State<_EditDispatchPlantForm> createState() => _EditDispatchPlantFormState();
}

class _EditDispatchPlantFormState extends State<_EditDispatchPlantForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  late final TextEditingController _plantBirdsCtl;
  late final TextEditingController _plantMissingCtl;
  late final TextEditingController _drownedCtl;
  late final TextEditingController _plantAvgWeightCtl;
  late final TextEditingController _plantTotalKgCtl;
  late final TextEditingController _saleBirdsCtl;
  late final TextEditingController _saleDiscountKgCtl;
  late final TextEditingController _saleTotalKgCtl;
  late final TextEditingController _saleAvgWeightCtl;
  late final TextEditingController _observationsCtl;

  @override
  void initState() {
    super.initState();
    final d = widget.dispatch;
    _plantBirdsCtl = TextEditingController(text: d.plantBirds?.toString() ?? '');
    _plantMissingCtl = TextEditingController(text: d.plantMissing.toString());
    _drownedCtl = TextEditingController(text: d.drowned.toString());
    _plantAvgWeightCtl = TextEditingController(text: d.plantAvgWeight?.toString() ?? '');
    _plantTotalKgCtl = TextEditingController(text: d.plantTotalKg?.toString() ?? '');
    _saleBirdsCtl = TextEditingController(text: d.saleBirds?.toString() ?? '');
    _saleDiscountKgCtl = TextEditingController(text: d.saleDiscountKg.toString());
    _saleTotalKgCtl = TextEditingController(text: d.saleTotalKg?.toString() ?? '');
    _saleAvgWeightCtl = TextEditingController(text: d.saleAvgWeight?.toString() ?? '');
    _observationsCtl = TextEditingController(text: d.observations ?? '');
  }

  @override
  void dispose() {
    _plantBirdsCtl.dispose();
    _plantMissingCtl.dispose();
    _drownedCtl.dispose();
    _plantAvgWeightCtl.dispose();
    _plantTotalKgCtl.dispose();
    _saleBirdsCtl.dispose();
    _saleDiscountKgCtl.dispose();
    _saleTotalKgCtl.dispose();
    _saleAvgWeightCtl.dispose();
    _observationsCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Completar Despacho #${widget.dispatch.manifestNumber}',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('Granja: ${widget.dispatch.totalBirds} pollos / ${widget.dispatch.farmTotalKg.toStringAsFixed(2)} kg',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),

              // Planta
              Text('DATOS PLANTA', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.orange.shade700, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: buildNumberField('Pollos recibidos', _plantBirdsCtl)),
                  const SizedBox(width: 8),
                  Expanded(child: buildNumberField('Faltantes', _plantMissingCtl)),
                  const SizedBox(width: 8),
                  Expanded(child: buildNumberField('Ahogados', _drownedCtl)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: buildNumberField('Peso prom. planta (kg)', _plantAvgWeightCtl)),
                  const SizedBox(width: 8),
                  Expanded(child: buildNumberField('Kilos planta', _plantTotalKgCtl)),
                ],
              ),
              const SizedBox(height: 16),

              // Venta
              Text('DATOS VENTA', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.green.shade700, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: buildNumberField('Pollos vendidos', _saleBirdsCtl)),
                  const SizedBox(width: 8),
                  Expanded(child: buildNumberField('Descuento kg', _saleDiscountKgCtl)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: buildNumberField('Kilos venta', _saleTotalKgCtl)),
                  const SizedBox(width: 8),
                  Expanded(child: buildNumberField('Peso prom. venta (kg)', _saleAvgWeightCtl)),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _observationsCtl,
                decoration: const InputDecoration(
                  labelText: 'Observaciones',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              SubmitButton(
                isLoading: _isSubmitting,
                label: 'Guardar Datos',
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    final data = <String, dynamic>{};


    void addIfNotEmpty(String key, String text, {bool isInt = false}) {
      if (text.isNotEmpty) {
        data[key] = isInt ? int.tryParse(text) : double.tryParse(text);
      }
    }

    addIfNotEmpty('plant_birds', _plantBirdsCtl.text, isInt: true);
    addIfNotEmpty('plant_missing', _plantMissingCtl.text, isInt: true);
    addIfNotEmpty('drowned', _drownedCtl.text, isInt: true);
    addIfNotEmpty('plant_avg_weight', _plantAvgWeightCtl.text);
    addIfNotEmpty('plant_total_kg', _plantTotalKgCtl.text);
    addIfNotEmpty('sale_birds', _saleBirdsCtl.text, isInt: true);
    addIfNotEmpty('sale_discount_kg', _saleDiscountKgCtl.text);
    addIfNotEmpty('sale_total_kg', _saleTotalKgCtl.text);
    addIfNotEmpty('sale_avg_weight', _saleAvgWeightCtl.text);

    if (_observationsCtl.text.isNotEmpty) {
      data['observations'] = _observationsCtl.text;
    }

    await widget.onSubmit(data);
    if (mounted) setState(() => _isSubmitting = false);
  }
}
