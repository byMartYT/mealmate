import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

// Provider für die ausgewählten Bilder (als Base64-Strings)
final pickedImagesProvider =
    StateNotifierProvider<PickedImagesNotifier, List<String>>((ref) {
      return PickedImagesNotifier();
    });

class PickedImagesNotifier extends StateNotifier<List<String>> {
  PickedImagesNotifier() : super([]);

  // Ausgewählte Bilder hinzufügen
  void addImages(List<String> base64Images) {
    state = [...state, ...base64Images];
  }

  // Alle Bilder löschen
  void clearImages() {
    state = [];
  }
}

class CameraPage extends ConsumerStatefulWidget {
  const CameraPage({super.key});

  @override
  ConsumerState<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends ConsumerState<CameraPage> {
  bool _isLoading = true;
  List<XFile>? _pickedImages;
  List<String> _base64Images = [];

  @override
  void initState() {
    super.initState();
    _pickMedia();
  }

  // Erkennt, ob wir auf einem Simulator/Emulator sind
  bool get _isSimulator {
    if (kIsWeb) return true;

    if (Platform.isAndroid) {
      // Android-Emulator-Erkennung basierend auf Geräteeigenschaften
      return !kReleaseMode &&
          (Platform.environment.containsKey('ANDROID_EMULATOR') ||
              Platform.environment.containsKey('ANDROID_SDK_ROOT'));
    } else if (Platform.isIOS) {
      // iOS-Simulator-Erkennung
      return !kReleaseMode &&
          (defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS);
    }

    return false;
  }

  Future<void> _pickMedia({bool manualTrigger = false}) async {
    // Wenn es ein manueller Aufruf ist oder die Bilder leer sind, Ladezustand setzen
    if (manualTrigger || _pickedImages == null) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final picker = ImagePicker();
      List<XFile>? selectedImages;

      // Wähle Bilder entweder aus der Galerie oder von der Kamera, je nach Gerät
      if (_isSimulator) {
        // Im Simulator die Galerie öffnen
        selectedImages = await picker.pickMultiImage();
      } else {
        // Auf echten Geräten die Kamera öffnen
        final XFile? image = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85, // Reduzierte Qualität für bessere Leistung
          maxWidth: 1200,
          maxHeight: 1200,
        );
        if (image != null) {
          selectedImages = [image];
        }
      }

      // Aktualisiere die ausgewählten Bilder, nur wenn der Benutzer etwas ausgewählt hat
      if (selectedImages != null && selectedImages.isNotEmpty) {
        setState(() {
          _pickedImages = selectedImages;
        });

        // Konvertiere alle Bilder zu Base64
        await _convertImagesToBase64();

        // Bilder dem Provider hinzufügen
        if (_base64Images.isNotEmpty) {
          ref.read(pickedImagesProvider.notifier).addImages(_base64Images);

          // Zeige Feedback an
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${_base64Images.length} pictures selected'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error while uploading: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error while loading the images: ${e.toString().split('\n')[0]}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _convertImagesToBase64() async {
    if (_pickedImages == null) return;

    _base64Images = [];

    for (var image in _pickedImages!) {
      try {
        // Bild als Bytes lesen
        final Uint8List bytes = await image.readAsBytes();

        // In Base64 konvertieren
        final String base64Image = base64Encode(bytes);

        _base64Images.add(base64Image);
      } catch (e) {
        debugPrint('Error while converting: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isSimulator ? 'Galery' : 'Camera'),
          actions: [
            // Nur anzeigen, wenn Bilder verfügbar sind
            if (_pickedImages != null && _pickedImages!.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.check),
                onPressed: () {
                  // Bilder zum Provider hinzufügen und zurück navigieren
                  if (_base64Images.isNotEmpty) {
                    ref.read(pickedImagesProvider.notifier).clearImages();
                    ref
                        .read(pickedImagesProvider.notifier)
                        .addImages(_base64Images);
                  }

                  // Navigiere zurück (sicher mit try/catch)
                  try {
                    context.pop();
                  } catch (e) {
                    // Falls es keine vorherige Seite gibt, zur Home-Seite navigieren
                    context.go('/home');
                  }
                },
                tooltip: 'Done',
              ),
          ],
        ),
        body:
            _isLoading
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        _isSimulator ? 'Choose images...' : 'Take picture...',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                )
                : _pickedImages == null || _pickedImages!.isEmpty
                ? _buildEmptyState()
                : _buildImagePreview(),
        floatingActionButton:
            _isLoading
                ? null
                : FloatingActionButton(
                  onPressed: () => _pickMedia(manualTrigger: true),
                  child: Icon(
                    _isSimulator ? Icons.photo_library : Icons.camera_alt,
                  ),
                  tooltip: _isSimulator ? 'Choose images' : 'Take picture',
                ),
      ),
    );
  }

  // Baut die Ansicht für den Fall, dass keine Bilder ausgewählt wurden
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isSimulator ? Icons.photo_library : Icons.camera_alt,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            _isSimulator
                ? 'Click on the button below to choose images'
                : 'Click on the button below to take a picture',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // Baut die Vorschau der ausgewählten Bilder
  Widget _buildImagePreview() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Chosen images: ${_pickedImages!.length}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _pickedImages!.length,
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      File(_pickedImages![index].path),
                      fit: BoxFit.cover,
                    ),
                    // Overlay für Löschfunktion
                    Positioned(
                      top: 5,
                      right: 5,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _pickedImages!.removeAt(index);
                              _base64Images.removeAt(index);

                              // Provider aktualisieren
                              ref
                                  .read(pickedImagesProvider.notifier)
                                  .clearImages();
                              if (_base64Images.isNotEmpty) {
                                ref
                                    .read(pickedImagesProvider.notifier)
                                    .addImages(_base64Images);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
