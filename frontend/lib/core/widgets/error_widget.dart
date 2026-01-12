import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/error_messages.dart';

class ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final bool useFriendlyMessage;

  const ErrorWidget({
    super.key, 
    required this.message, 
    this.onRetry,
    this.useFriendlyMessage = true,
  });

  @override
  Widget build(BuildContext context) {
    final displayMessage = useFriendlyMessage 
        ? ErrorMessages.getFriendlyMessage(message)
        : message;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              displayMessage,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
