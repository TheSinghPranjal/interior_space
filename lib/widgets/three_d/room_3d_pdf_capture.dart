import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/pdf_export_settings.dart';
import '../../models/room_3d_export_images.dart';
import 'room_3d_viewer.dart';

/// Loads the 3D viewer off-screen and captures front/top views for PDF export.
Future<ApartmentPdf3DCaptureResult> captureRoom3DImagesForPdf(
  BuildContext context, {
  required bool apartmentMode,
  required PdfExportSettings pdfSettings,
}) async {
  if (!pdfSettings.shouldCapture3d) {
    return const ApartmentPdf3DCaptureResult();
  }

  final result =
      await Navigator.of(context).push<ApartmentPdf3DCaptureResult>(
    PageRouteBuilder(
      opaque: true,
      barrierDismissible: false,
      pageBuilder: (context, animation, secondaryAnimation) =>
          Room3DPdfCapturePage(
            apartmentMode: apartmentMode,
            pdfSettings: pdfSettings,
          ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
  return result ?? const ApartmentPdf3DCaptureResult();
}

class Room3DPdfCapturePage extends ConsumerStatefulWidget {
  const Room3DPdfCapturePage({
    super.key,
    required this.apartmentMode,
    required this.pdfSettings,
  });

  final bool apartmentMode;
  final PdfExportSettings pdfSettings;

  @override
  ConsumerState<Room3DPdfCapturePage> createState() => _Room3DPdfCapturePageState();
}

class _Room3DPdfCapturePageState extends ConsumerState<Room3DPdfCapturePage> {
  Future<ApartmentPdf3DCaptureResult> Function(PdfExportSettings settings)?
      _capture;
  bool _started = false;

  Future<void> _runCapture() async {
    if (_started || _capture == null) return;
    _started = true;

    try {
      await Future.delayed(const Duration(milliseconds: 350));
      final result = await _capture!(widget.pdfSettings);
      if (mounted) Navigator.pop(context, result);
    } catch (_) {
      if (mounted) {
        Navigator.pop(context, const ApartmentPdf3DCaptureResult());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121816),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Room3DViewer(
            showControls: false,
            apartmentMode: widget.apartmentMode,
            onCaptureReady: (capture) {
              _capture = capture;
              _runCapture();
            },
          ),
          Container(
            color: Colors.black.withValues(alpha: 0.72),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  widget.apartmentMode
                      ? 'Capturing apartment top view and room previews...'
                      : 'Capturing 3D preview...',
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
