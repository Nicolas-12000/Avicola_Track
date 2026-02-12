import 'package:flutter/material.dart';

/// Widget reutilizable para estado de error con botón de reintento.
/// Usado en daily_records_screen, dispatch_records_screen, etc.
class ErrorStateWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorStateWidget({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: theme.colorScheme.error)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

/// Widget reutilizable para estado vacío con ícono y texto.
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18, color: Colors.grey)),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle!, style: const TextStyle(color: Colors.grey)),
          ],
        ],
      ),
    );
  }
}

/// Botón de envío con estado de carga integrado.
class SubmitButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  final String label;
  final String loadingLabel;
  final IconData icon;

  const SubmitButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    this.label = 'Guardar',
    this.loadingLabel = 'Guardando...',
    this.icon = Icons.save,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon),
      label: Text(isLoading ? loadingLabel : label),
    );
  }
}

/// Encabezado de sección con barra de color lateral.
class SectionHeader extends StatelessWidget {
  final String title;
  final Color color;

  const SectionHeader({
    super.key,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila de info label-value reutilizable para cards de detalle.
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isWarning;

  const InfoRow(
    this.label,
    this.value, {
    super.key,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isWarning ? Colors.red : null,
                ),
          ),
        ],
      ),
    );
  }
}

/// Campo de formulario numérico reutilizable.
Widget buildNumberField(
  String label,
  TextEditingController controller, {
  bool required = false,
  bool decimal = true,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    controller: controller,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      isDense: true,
    ),
    keyboardType: decimal
        ? const TextInputType.numberWithOptions(decimal: true)
        : TextInputType.number,
    validator: validator ??
        (required
            ? (v) => v == null || v.isEmpty ? 'Requerido' : null
            : null),
  );
}
