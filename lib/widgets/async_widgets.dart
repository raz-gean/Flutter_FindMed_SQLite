import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;
  const LoadingIndicator({super.key, this.message});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
        if (message != null) ...[
          const SizedBox(height: 12),
          Text(message!, style: const TextStyle(fontSize: 12)),
        ],
      ],
    ),
  );
}

class ErrorRetry extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;
  const ErrorRetry({super.key, this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
        const SizedBox(height: 12),
        Text(message ?? 'Something went wrong.', textAlign: TextAlign.center),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

class AsyncStateSwitcher extends StatelessWidget {
  final bool loading;
  final bool error;
  final Widget child;
  final VoidCallback onRetry;
  final String? loadingMessage;
  final String? errorMessage;
  const AsyncStateSwitcher({
    super.key,
    required this.loading,
    required this.error,
    required this.child,
    required this.onRetry,
    this.loadingMessage,
    this.errorMessage,
  });
  @override
  Widget build(BuildContext context) {
    if (loading) return LoadingIndicator(message: loadingMessage);
    if (error) return ErrorRetry(message: errorMessage, onRetry: onRetry);
    return child;
  }
}
