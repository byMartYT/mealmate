import 'package:flutter/material.dart';

class ErrorScreen extends StatelessWidget {
  final String title;
  final String message;
  final bool withScaffold;
  final String? appBarTitle;
  final String? actionButtonText;
  final VoidCallback? onActionPressed;

  const ErrorScreen({
    super.key,
    this.title = 'Error',
    required this.message,
    this.withScaffold = false,
    this.appBarTitle = 'Error',
    this.actionButtonText,
    this.onActionPressed,
  });

  /// Factory constructor for creating a general error screen
  factory ErrorScreen.general({
    required String message,
    bool withScaffold = false,
    String? appBarTitle,
    String? actionButtonText,
    VoidCallback? onActionPressed,
  }) {
    return ErrorScreen(
      message: message,
      withScaffold: withScaffold,
      appBarTitle: appBarTitle,
      actionButtonText: actionButtonText,
      onActionPressed: onActionPressed,
    );
  }

  /// Factory constructor for creating a network error screen
  factory ErrorScreen.network({
    String message = 'Network connection error',
    bool withScaffold = false,
    String? appBarTitle,
    String? actionButtonText = 'Retry',
    VoidCallback? onActionPressed,
  }) {
    return ErrorScreen(
      title: 'Connection Error',
      message: message,
      withScaffold: withScaffold,
      appBarTitle: appBarTitle,
      actionButtonText: actionButtonText,
      onActionPressed: onActionPressed,
    );
  }

  /// Factory constructor for retry functionality
  factory ErrorScreen.retry({
    required String message,
    required VoidCallback onRetry,
    bool withScaffold = false,
    String? appBarTitle,
  }) {
    return ErrorScreen(
      message: message,
      withScaffold: withScaffold,
      appBarTitle: appBarTitle,
      actionButtonText: 'Retry',
      onActionPressed: onRetry,
    );
  }

  /// Factory constructor for back action
  factory ErrorScreen.goBack({
    required String message,
    required VoidCallback onBack,
    bool withScaffold = false,
    String? appBarTitle,
  }) {
    return ErrorScreen(
      message: message,
      withScaffold: withScaffold,
      appBarTitle: appBarTitle,
      actionButtonText: 'Back',
      onActionPressed: onBack,
    );
  }

  /// Show error dialog (non-widget method)
  static Future<void> showErrorDialog({
    required BuildContext context,
    required String message,
    String title = 'Error',
    String? actionButtonText,
    VoidCallback? onActionPressed,
  }) async {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              if (actionButtonText != null && onActionPressed != null)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onActionPressed();
                  },
                  child: Text(actionButtonText),
                ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            if (title != 'Error') ...[
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            if (actionButtonText != null && onActionPressed != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onActionPressed,
                child: Text(actionButtonText!),
              ),
            ],
          ],
        ),
      ),
    );

    if (withScaffold) {
      return Scaffold(
        appBar: appBarTitle != null ? AppBar(title: Text(appBarTitle!)) : null,
        body: content,
      );
    }

    return content;
  }
}
