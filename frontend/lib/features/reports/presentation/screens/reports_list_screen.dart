import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../farms/presentation/providers/farms_provider.dart';
import '../providers/reports_provider.dart';
import '../../domain/reports_repository.dart';

class ReportsListScreen extends ConsumerStatefulWidget {
  const ReportsListScreen({super.key});

  @override
  ConsumerState<ReportsListScreen> createState() => _ReportsListScreenState();
}

class _ReportsListScreenState extends ConsumerState<ReportsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? selectedFarmId;
  DateTimeRange? dateRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportsProvider.notifier).loadReports();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportsState = ref.watch(reportsProvider);
    final farmsState = ref.watch(farmsProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Reportes'),
        backgroundColor: AppColors.primary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Templates'),
            Tab(text: 'Historial'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Templates Tab
          _buildTemplatesTab(reportsState, farmsState),

          // History Tab
          _buildHistoryTab(reportsState),
        ],
      ),
    );
  }

  Widget _buildTemplatesTab(ReportsState reportsState, FarmsState farmsState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filters Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filtros',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Farm Selector
                  DropdownButtonFormField<int>(
                    initialValue: selectedFarmId,
                    decoration: const InputDecoration(
                      labelText: 'Granja',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.home),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Todas las granjas'),
                      ),
                      ...farmsState.farms.map(
                        (farm) => DropdownMenuItem(
                          value: farm.id,
                          child: Text(farm.name),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedFarmId = value;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Date Range
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        initialDateRange: dateRange,
                      );
                      if (picked != null) {
                        setState(() {
                          dateRange = picked;
                        });
                      }
                    },
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      dateRange == null
                          ? 'Seleccionar rango de fechas'
                          : '${DateFormat('dd/MM/yyyy').format(dateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(dateRange!.end)}',
                    ),
                  ),

                  if (dateRange != null)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          dateRange = null;
                        });
                      },
                      icon: const Icon(Icons.clear),
                      label: const Text('Limpiar fechas'),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Templates Grid
          const Text(
            'Selecciona un tipo de reporte',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 900
                  ? 4
                  : constraints.maxWidth > 600
                  ? 3
                  : 2;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: reportsState.templates.length,
                itemBuilder: (context, index) {
                  final template = reportsState.templates[index];
                  return _buildTemplateCard(template);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(ReportTemplate template) {
    final canGenerate =
        selectedFarmId != null || !template.requiredFilters.contains('farmId');

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: canGenerate ? () => _generateReport(template) : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(template.icon, style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                template.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                template.description,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              if (!canGenerate)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Requiere granja',
                    style: TextStyle(fontSize: 10, color: Colors.orange),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTab(ReportsState reportsState) {
    if (reportsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (reportsState.reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay reportes generados',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Genera tu primer reporte desde la pestaña Templates',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reportsState.reports.length,
      itemBuilder: (context, index) {
        final report = reportsState.reports[index];
        return _buildReportCard(report);
      },
    );
  }

  Widget _buildReportCard(Report report) {
    final typeIcon = _getReportIcon(report.type);
    final typeColor = _getReportColor(report.type);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: typeColor.withValues(alpha: 0.1),
          child: Icon(typeIcon, color: typeColor),
        ),
        title: Text(
          report.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(report.farmName ?? 'Todas las granjas'),
            Text(
              'Generado: ${DateFormat('dd/MM/yyyy HH:mm').format(report.generatedAt)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleReportAction(value, report),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility),
                  SizedBox(width: 8),
                  Text('Ver'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share),
                  SizedBox(width: 8),
                  Text('Compartir'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getReportIcon(String type) {
    switch (type) {
      case 'production':
        return Icons.trending_up;
      case 'mortality':
        return Icons.trending_down;
      case 'inventory':
        return Icons.inventory;
      case 'complete':
        return Icons.description;
      default:
        return Icons.description;
    }
  }

  Color _getReportColor(String type) {
    switch (type) {
      case 'production':
        return Colors.green;
      case 'mortality':
        return Colors.red;
      case 'inventory':
        return Colors.blue;
      case 'complete':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Future<void> _generateReport(ReportTemplate template) async {
    if (selectedFarmId == null && template.requiredFilters.contains('farmId')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una granja'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Generando reporte...'),
              ],
            ),
          ),
        ),
      ),
    );

    final success = await ref
        .read(reportsProvider.notifier)
        .generateReport(
          type: template.type,
          farmId: selectedFarmId!,
          startDate: dateRange?.start,
          endDate: dateRange?.end,
        );

    if (mounted) {
      Navigator.of(context).pop(); // Close loading dialog

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reporte generado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        // Switch to history tab
        _tabController.animateTo(1);
      } else {
        final errorMessage =
            ref.read(reportsProvider).errorMessage ?? 'Error desconocido';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $errorMessage'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleReportAction(String action, Report report) {
    switch (action) {
      case 'view':
        _viewReport(report);
        break;
      case 'share':
        _shareReport(context, report);
        break;
      case 'delete':
        _deleteReport(report);
        break;
    }
  }

  void _viewReport(Report report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(report.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReportInfoRow(Icons.category, 'Tipo', report.type),
            _buildReportInfoRow(
              Icons.calendar_today,
              'Generado',
              '${report.generatedAt.day}/${report.generatedAt.month}/${report.generatedAt.year}',
            ),
            _buildReportInfoRow(
              Icons.description,
              'Tipo de datos',
              report.data.runtimeType.toString(),
            ),
            const Divider(height: 24),
            const Text(
              'Contenido del Reporte:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                report.data.toString(),
                style: const TextStyle(fontSize: 12),
                maxLines: 10,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _shareReport(context, report);
            },
            icon: const Icon(Icons.share),
            label: const Text('Compartir'),
          ),
        ],
      ),
    );
  }

  void _shareReport(BuildContext context, Report report) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Compartir Reporte'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Enviar por Email'),
              onTap: () {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '📧 Reporte "${report.title}" enviado por email',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Exportar a PDF'),
              onTap: () {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '📄 Reporte "${report.title}" exportado a PDF',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Exportar a Excel'),
              onTap: () {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '📊 Reporte "${report.title}" exportado a Excel',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReport(Report report) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar reporte'),
        content: Text('¿Estás seguro de eliminar "${report.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true && report.id != null) {
      final success = await ref
          .read(reportsProvider.notifier)
          .deleteReport(report.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Reporte eliminado' : 'Error al eliminar reporte',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  /// Widget helper para mostrar información del reporte
  Widget _buildReportInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
