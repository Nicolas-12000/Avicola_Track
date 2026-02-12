import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../data/models/daily_record_model.dart';
import '../providers/daily_dispatch_provider.dart';

class DailyRecordsScreen extends ConsumerStatefulWidget {
  final int flockId;
  final String? flockName;

  const DailyRecordsScreen({
    super.key,
    required this.flockId,
    this.flockName,
  });

  @override
  ConsumerState<DailyRecordsScreen> createState() => _DailyRecordsScreenState();
}

class _DailyRecordsScreenState extends ConsumerState<DailyRecordsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(dailyRecordsProvider.notifier).loadDailyRecords(flockId: widget.flockId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dailyRecordsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.flockName != null
            ? 'Registro Diario - ${widget.flockName}'
            : 'Registro Diario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(dailyRecordsProvider.notifier).loadDailyRecords(flockId: widget.flockId);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Registro'),
      ),
      body: _buildBody(state, theme),
    );
  }

  Widget _buildBody(DailyRecordsState state, ThemeData theme) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return ErrorStateWidget(
        message: state.error!,
        onRetry: () {
          ref.read(dailyRecordsProvider.notifier).loadDailyRecords(flockId: widget.flockId);
        },
      );
    }
    if (state.items.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.calendar_today,
        title: 'No hay registros diarios',
        subtitle: 'Toca + para agregar el primer registro',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: state.items.length,
      itemBuilder: (context, index) {
        final record = state.items[state.items.length - 1 - index]; // Más reciente primero
        return _DailyRecordCard(record: record);
      },
    );
  }

  void _showCreateDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _CreateDailyRecordForm(
        flockId: widget.flockId,
        onSubmit: (data) async {
          final success = await ref.read(dailyRecordsProvider.notifier).createDailyRecord(data);
          if (success && mounted) {
            Navigator.of(ctx).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Registro diario creado exitosamente')),
            );
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(ref.read(dailyRecordsProvider).error ?? 'Error al crear registro'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }
}

class _DailyRecordCard extends StatelessWidget {
  final DailyRecordModel record;

  const _DailyRecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('dd/MM/yyyy').format(record.date);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            'D${record.dayNumber}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        title: Text('$dateStr - Semana ${record.weekNumber}'),
        subtitle: Text(
          'Mort: ${record.totalMortality} | Saldo: ${record.totalBalance} | Alim: ${record.totalFeedConsumedKg.toStringAsFixed(1)} kg',
          style: theme.textTheme.bodySmall,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Encabezado tabla
                _buildTableHeader(theme),
                const Divider(),
                // Fila Machos
                _buildGenderRow('♂ Machos', record.mortalityMale, record.processOutputMale,
                    record.balanceMale, record.feedConsumedKgMale, record.feedPerBirdGrMale,
                    record.weightMale, record.feedConversionMale, record.dailyAvgWeightGainMale, theme),
                const Divider(height: 4),
                // Fila Hembras
                _buildGenderRow('♀ Hembras', record.mortalityFemale, record.processOutputFemale,
                    record.balanceFemale, record.feedConsumedKgFemale, record.feedPerBirdGrFemale,
                    record.weightFemale, record.feedConversionFemale, record.dailyAvgWeightGainFemale, theme),
                if (record.temperature != null) ...[
                  const Divider(),
                  Row(
                    children: [
                      const Icon(Icons.thermostat, size: 16),
                      const SizedBox(width: 4),
                      Text('Temp: ${record.temperature!.toStringAsFixed(1)}°C'),
                    ],
                  ),
                ],
                if (record.notes != null && record.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.note, size: 16),
                      const SizedBox(width: 4),
                      Expanded(child: Text(record.notes!)),
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

  Widget _buildTableHeader(ThemeData theme) {
    final style = theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold);
    return Row(
      children: [
        SizedBox(width: 70, child: Text('', style: style)),
        Expanded(child: Text('Mort', style: style, textAlign: TextAlign.center)),
        Expanded(child: Text('Proc', style: style, textAlign: TextAlign.center)),
        Expanded(child: Text('Saldo', style: style, textAlign: TextAlign.center)),
        Expanded(child: Text('Alim kg', style: style, textAlign: TextAlign.center)),
        Expanded(child: Text('g/ave', style: style, textAlign: TextAlign.center)),
        Expanded(child: Text('Peso g', style: style, textAlign: TextAlign.center)),
        Expanded(child: Text('Conv', style: style, textAlign: TextAlign.center)),
        Expanded(child: Text('Gan/d', style: style, textAlign: TextAlign.center)),
      ],
    );
  }

  Widget _buildGenderRow(
    String label,
    int mortality,
    int processOutput,
    int balance,
    double feedKg,
    double feedPerBird,
    double? weight,
    double? conversion,
    double? dailyGain,
    ThemeData theme,
  ) {
    final style = theme.textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 70, child: Text(label, style: style?.copyWith(fontWeight: FontWeight.w600))),
          Expanded(child: Text('$mortality', style: style, textAlign: TextAlign.center)),
          Expanded(child: Text('$processOutput', style: style, textAlign: TextAlign.center)),
          Expanded(child: Text('$balance', style: style, textAlign: TextAlign.center)),
          Expanded(child: Text(feedKg.toStringAsFixed(1), style: style, textAlign: TextAlign.center)),
          Expanded(child: Text(feedPerBird.toStringAsFixed(0), style: style, textAlign: TextAlign.center)),
          Expanded(child: Text(weight?.toStringAsFixed(0) ?? '-', style: style, textAlign: TextAlign.center)),
          Expanded(child: Text(conversion?.toStringAsFixed(2) ?? '-', style: style, textAlign: TextAlign.center)),
          Expanded(child: Text(dailyGain?.toStringAsFixed(1) ?? '-', style: style, textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}

class _CreateDailyRecordForm extends StatefulWidget {
  final int flockId;
  final Future<void> Function(Map<String, dynamic> data) onSubmit;

  const _CreateDailyRecordForm({required this.flockId, required this.onSubmit});

  @override
  State<_CreateDailyRecordForm> createState() => _CreateDailyRecordFormState();
}

class _CreateDailyRecordFormState extends State<_CreateDailyRecordForm> {
  final _formKey = GlobalKey<FormState>();
  DateTime _date = DateTime.now();
  bool _isSubmitting = false;

  // Machos
  final _mortalityMaleCtl = TextEditingController(text: '0');
  final _processOutputMaleCtl = TextEditingController(text: '0');
  final _feedKgMaleCtl = TextEditingController(text: '0');
  final _weightMaleCtl = TextEditingController();

  // Hembras
  final _mortalityFemaleCtl = TextEditingController(text: '0');
  final _processOutputFemaleCtl = TextEditingController(text: '0');
  final _feedKgFemaleCtl = TextEditingController(text: '0');
  final _weightFemaleCtl = TextEditingController();

  // General
  final _temperatureCtl = TextEditingController();
  final _notesCtl = TextEditingController();

  @override
  void dispose() {
    _mortalityMaleCtl.dispose();
    _processOutputMaleCtl.dispose();
    _feedKgMaleCtl.dispose();
    _weightMaleCtl.dispose();
    _mortalityFemaleCtl.dispose();
    _processOutputFemaleCtl.dispose();
    _feedKgFemaleCtl.dispose();
    _weightFemaleCtl.dispose();
    _temperatureCtl.dispose();
    _notesCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
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
                  const Icon(Icons.calendar_today),
                  const SizedBox(width: 8),
                  Text(
                    'Nuevo Registro Diario',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
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
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
              ),
              const SizedBox(height: 16),

              // === MACHOS ===
              Text('♂ MACHOS', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.blue, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: buildNumberField('Mortalidad', _mortalityMaleCtl, decimal: false,
                    validator: _intValidator)),
                  const SizedBox(width: 8),
                  Expanded(child: buildNumberField('Salida Proceso', _processOutputMaleCtl, decimal: false,
                    validator: _intValidator)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: buildNumberField('Alimento (kg)', _feedKgMaleCtl,
                    validator: _decimalValidator(true))),
                  const SizedBox(width: 8),
                  Expanded(child: buildNumberField('Peso prom. (g)', _weightMaleCtl,
                    validator: _decimalValidator(false))),
                ],
              ),
              const SizedBox(height: 16),

              // === HEMBRAS ===
              Text('♀ HEMBRAS', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.pink, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: buildNumberField('Mortalidad', _mortalityFemaleCtl, decimal: false,
                    validator: _intValidator)),
                  const SizedBox(width: 8),
                  Expanded(child: buildNumberField('Salida Proceso', _processOutputFemaleCtl, decimal: false,
                    validator: _intValidator)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: buildNumberField('Alimento (kg)', _feedKgFemaleCtl,
                    validator: _decimalValidator(true))),
                  const SizedBox(width: 8),
                  Expanded(child: buildNumberField('Peso prom. (g)', _weightFemaleCtl,
                    validator: _decimalValidator(false))),
                ],
              ),
              const SizedBox(height: 16),

              // === GENERAL ===
              Text('GENERAL', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              buildNumberField('Temperatura (°C)', _temperatureCtl,
                validator: _decimalValidator(false)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesCtl,
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
                label: 'Guardar Registro',
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _intValidator(String? v) {
    if (v == null || v.isEmpty) return null;
    if (int.tryParse(v) == null) return 'Número inválido';
    return null;
  }

  String? Function(String?) _decimalValidator(bool isRequired) {
    return (String? v) {
      if (!isRequired && (v == null || v.isEmpty)) return null;
      if (isRequired && (v == null || v.isEmpty)) return 'Requerido';
      if (double.tryParse(v!) == null) return 'Número inválido';
      return null;
    };
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final data = {
      'flock': widget.flockId,
      'date': _date.toIso8601String().split('T')[0],
      'mortality_male': int.tryParse(_mortalityMaleCtl.text) ?? 0,
      'mortality_female': int.tryParse(_mortalityFemaleCtl.text) ?? 0,
      'process_output_male': int.tryParse(_processOutputMaleCtl.text) ?? 0,
      'process_output_female': int.tryParse(_processOutputFemaleCtl.text) ?? 0,
      'feed_consumed_kg_male': double.tryParse(_feedKgMaleCtl.text) ?? 0,
      'feed_consumed_kg_female': double.tryParse(_feedKgFemaleCtl.text) ?? 0,
      'weight_male': _weightMaleCtl.text.isNotEmpty ? double.tryParse(_weightMaleCtl.text) : null,
      'weight_female': _weightFemaleCtl.text.isNotEmpty ? double.tryParse(_weightFemaleCtl.text) : null,
      'temperature': _temperatureCtl.text.isNotEmpty ? double.tryParse(_temperatureCtl.text) : null,
      'notes': _notesCtl.text,
    };

    await widget.onSubmit(data);
    if (mounted) setState(() => _isSubmitting = false);
  }
}
