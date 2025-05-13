import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  /// Title displayed in the loading screen
  final String title;

  /// Primary message displayed below the loading indicator
  final String message;

  /// Secondary message displayed as a subtitle (optional)
  final String? subtitle;

  /// Whether to show the loading screen with a scaffold or just the content
  final bool withScaffold;

  /// AppBar title (only used when withScaffold is true)
  final String? appBarTitle;

  const LoadingScreen({
    super.key,
    this.title = '',
    this.message = 'Loading...',
    this.subtitle,
    this.withScaffold = false,
    this.appBarTitle,
  });

  /// Factory constructor for creating a loading screen for recipe generation
  factory LoadingScreen.recipeGeneration({
    bool withScaffold = false,
    String? appBarTitle,
  }) {
    return LoadingScreen(
      message: 'Creating your recipe...',
      subtitle: 'Our chef is working on the details',
      withScaffold: withScaffold,
      appBarTitle: appBarTitle,
    );
  }

  /// Factory constructor for creating a loading screen for ingredient extraction
  factory LoadingScreen.ingredientExtraction({
    bool withScaffold = false,
    String? appBarTitle,
  }) {
    return LoadingScreen(
      message: 'Analyzing image...',
      subtitle: 'The AI is searching for ingredients',
      withScaffold: withScaffold,
      appBarTitle: appBarTitle,
    );
  }

  /// Factory constructor for creating a loading screen for image selection
  factory LoadingScreen.imageSelection(
    bool isSimulator, {
    bool withScaffold = false,
    String? appBarTitle,
  }) {
    return LoadingScreen(
      message: isSimulator ? 'Choose images...' : 'Take picture...',
      withScaffold: withScaffold,
      appBarTitle: appBarTitle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ],
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
