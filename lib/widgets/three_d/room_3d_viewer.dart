import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../models/pdf_export_settings.dart';
import '../../models/room_3d_export_images.dart';
import '../../providers/app_mode_provider.dart';
import '../../providers/project_provider.dart';
import '../../providers/room_design_provider.dart';
import '../../services/room_scene_builder.dart';
import '../../services/room_viewer_html_loader.dart';

typedef Room3DControllerCallback = void Function(
  Future<ApartmentPdf3DCaptureResult> Function(
    PdfExportSettings settings,
    PdfExportCaptureScope scope,
  ) captureForPdfExport,
);

class Room3DViewer extends ConsumerStatefulWidget {
  const Room3DViewer({
    super.key,
    this.showControls = true,
    this.apartmentMode = false,
    this.onCaptureReady,
  });

  final bool showControls;
  final bool apartmentMode;
  final Room3DControllerCallback? onCaptureReady;

  @override
  ConsumerState<Room3DViewer> createState() => _Room3DViewerState();
}

class _Room3DViewerState extends ConsumerState<Room3DViewer> {
  InAppWebViewController? _controller;
  bool _isReady = false;
  bool _isLoading = true;
  String? _loadError;
  String? _htmlContent;
  Timer? _apartmentSceneDebounce;
  Map<String, dynamic>? _pendingScenePayload;

  @override
  void dispose() {
    _apartmentSceneDebounce?.cancel();
    super.dispose();
  }

  void _scheduleApartmentScenePush() {
    _apartmentSceneDebounce?.cancel();
    _apartmentSceneDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _pushScene();
    });
  }

  @override
  void initState() {
    super.initState();
    _loadHtml();
  }

  Future<void> _loadHtml() async {
    try {
      final html = await RoomViewerHtmlLoader.load();
      if (mounted) {
        setState(() => _htmlContent = html);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadError = 'Failed to load 3D engine: $e');
      }
    }
  }

  Future<bool> _pushSceneJson(String json) async {
    if (_controller == null) return false;
    final sceneObject = jsonDecode(json) as Map<String, dynamic>;
    _pendingScenePayload = sceneObject;

    try {
      final result = await _controller!.callAsyncJavaScript(
        functionBody: '''
          try {
            if (typeof updateRoomScene !== 'function') return 'no_handler';
            var scene = await window.flutter_inappwebview.callHandler('fetchScenePayload');
            if (!scene) return 'error:no_scene';
            updateRoomScene(scene);
            return 'ok';
          } catch (e) {
            return 'error:' + (e.message || e);
          }
        ''',
        arguments: const {},
      );

      final value = result?.value?.toString();
      if (value == 'ok') return true;
      if (value != null && value.startsWith('error:')) {
        if (kDebugMode) debugPrint('Scene handler push failed: $value');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Scene handler push failed, falling back: $e');
      }
    } finally {
      _pendingScenePayload = null;
    }

    try {
      final embedded = jsonEncode(sceneObject);
      final result = await _controller!.evaluateJavascript(
        source: '''
          (function() {
            try {
              if (typeof updateRoomScene !== 'function') return 'no_handler';
              updateRoomScene($embedded);
              return 'ok';
            } catch(e) {
              return 'error:' + (e.message || e);
            }
          })();
        ''',
      );

      final value = result?.toString();
      if (value != null && value.startsWith('error:')) {
        if (mounted) setState(() => _loadError = value);
        return false;
      }
      return true;
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = 'Scene update failed: $e';
          _isLoading = false;
        });
      }
      return false;
    }
  }

  Future<void> _pushScene() async {
    if (_controller == null) return;
    if (mounted) setState(() => _isLoading = true);
    try {
      final showLabels = ref.read(showWallDimensionLabelsProvider);
      final premium = ref.read(premiumFurnitureProvider);
      final isApartment = widget.apartmentMode ||
          ref.read(appSpaceModeProvider) == AppSpaceMode.apartment;
      final String json;
      if (isApartment) {
        final project = ref.read(projectProvider);
        final builder = ref.read(apartmentSceneBuilderProvider);
        json = await builder.buildSceneJson(
          project,
          showWallDimensionLabels: showLabels,
          premiumFurniture: premium,
        );
      } else {
        final design = ref.read(roomDesignProvider);
        final builder = ref.read(roomSceneBuilderProvider);
        json = await builder.buildSceneJson(
          design,
          showWallDimensionLabels: showLabels,
          premiumFurniture: premium,
        );
      }

      final ok = await _pushSceneJson(json);
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (ok) _loadError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = 'Scene update failed: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _setCameraMode(CameraMode mode) async {
    if (_controller == null) return;
    await _controller!.evaluateJavascript(
      source: "setCameraMode('${mode.name}');",
    );
  }

  Future<void> _orbitZoom({required bool zoomIn}) async {
    if (_controller == null) return;
    await _controller!.evaluateJavascript(
      source: zoomIn ? 'orbitZoomIn();' : 'orbitZoomOut();',
    );
  }

  Future<Uint8List?> _captureCameraView(String mode) async {
    if (_controller == null || !_isReady) return null;
    try {
      await _controller!.evaluateJavascript(source: "setCameraMode('$mode');");
      await Future.delayed(const Duration(milliseconds: 350));
      final result = await _controller!.evaluateJavascript(
        source: 'captureScreenshot();',
      );
      if (result == null) return null;
      var dataUrl = result.toString();
      if (dataUrl.startsWith('"') && dataUrl.endsWith('"')) {
        dataUrl = jsonDecode(dataUrl) as String;
      }
      return _decodeDataUrl(dataUrl);
    } catch (e) {
      if (kDebugMode) debugPrint('3D view capture failed ($mode): $e');
      return null;
    }
  }

  Future<Room3DExportImages?> _captureExportViews(PdfExportSettings settings) async {
    if (_controller == null || !_isReady) return null;

    final previousMode = ref.read(cameraModeProvider);
    Uint8List? front;
    Uint8List? top;

    if (settings.includeFrontView) {
      front = await _captureCameraView('front');
    }
    if (settings.includeTopView) {
      top = await _captureCameraView('top');
    }

    await _setCameraMode(previousMode);

    if (front == null && top == null) return null;
    return Room3DExportImages(front: front, top: top);
  }

  Future<ApartmentPdf3DCaptureResult> _captureForPdfExport(
    PdfExportSettings settings,
    PdfExportCaptureScope scope,
  ) async {
    if (_controller == null || !_isReady || !settings.shouldCapture3d) {
      return const ApartmentPdf3DCaptureResult();
    }

    final project = ref.read(projectProvider);
    final rooms = switch (scope) {
      PdfExportCaptureScope.singleRoom => [project.activeRoom],
      PdfExportCaptureScope.allRooms => project.roomsForActiveApartment,
      PdfExportCaptureScope.apartment => project.roomsForActiveApartment,
    };
    if (rooms.isEmpty) return const ApartmentPdf3DCaptureResult();

    final builder = ref.read(roomSceneBuilderProvider);
    final apartmentBuilder = ref.read(apartmentSceneBuilderProvider);
    final showLabels = ref.read(showWallDimensionLabelsProvider);
    final premium = ref.read(premiumFurnitureProvider);
    final captures = <int, Room3DExportImages>{};
    Uint8List? apartmentTopView;
    Uint8List? apartmentFrontView;

    if (scope == PdfExportCaptureScope.apartment) {
      final apartmentJson = await apartmentBuilder.buildSceneJson(
        project,
        showWallDimensionLabels: showLabels,
        premiumFurniture: premium,
      );
      final pushedApartment = await _pushSceneJson(apartmentJson);
      if (pushedApartment) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (settings.includeTopView) {
          apartmentTopView = await _captureCameraView('top');
        }
        if (settings.includeFrontView) {
          apartmentFrontView = await _captureCameraView('front');
        }
      }
    }

    for (var i = 0; i < rooms.length; i++) {
      final sceneJson = await builder.buildSceneJson(
        rooms[i],
        showWallDimensionLabels: showLabels,
        premiumFurniture: premium,
      );
      final pushed = await _pushSceneJson(sceneJson);
      if (!pushed) continue;

      await Future.delayed(const Duration(milliseconds: 450));
      final views = await _captureExportViews(settings);
      if (views != null && views.hasAny) {
        captures[i] = views;
      }
    }

    await _pushScene();
    return ApartmentPdf3DCaptureResult(
      roomImages: captures,
      apartmentTopView: apartmentTopView,
      apartmentFrontView: apartmentFrontView,
    );
  }

  Uint8List? _decodeDataUrl(String? dataUrl) {
    if (dataUrl == null || !dataUrl.startsWith('data:image')) return null;
    return base64Decode(dataUrl.split(',').last);
  }

  void _notifyCaptureReady() {
    widget.onCaptureReady?.call(_captureForPdfExport);
  }

  @override
  Widget build(BuildContext context) {
    final cameraMode = ref.watch(cameraModeProvider);
    final showWallLabels = ref.watch(showWallDimensionLabelsProvider);
    final premiumFurniture = ref.watch(premiumFurnitureProvider);

    ref.listen(roomDesignProvider, (_, _) {
      final isApartment = widget.apartmentMode ||
          ref.read(appSpaceModeProvider) == AppSpaceMode.apartment;
      if (_isReady && !isApartment) _pushScene();
    });

    ref.listen(projectProvider, (_, _) {
      final isApartment = widget.apartmentMode ||
          ref.read(appSpaceModeProvider) == AppSpaceMode.apartment;
      if (_isReady && isApartment) _scheduleApartmentScenePush();
    });

    ref.listen(cameraModeProvider, (_, next) {
      if (_isReady) _setCameraMode(next);
    });

    ref.listen(showWallDimensionLabelsProvider, (_, _) {
      if (_isReady) _pushScene();
    });

    ref.listen(premiumFurnitureProvider, (_, _) {
      if (_isReady) _pushScene();
    });

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 46),
              const SizedBox(height: 16),
              Text(
                _loadError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _loadError = null;
                    _isLoading = true;
                    _isReady = false;
                    _htmlContent = null;
                  });
                  _loadHtml();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_htmlContent == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Preparing 3D engine...', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    return Stack(
      children: [
        InAppWebView(
          initialSettings: InAppWebViewSettings(
            transparentBackground: true,
            javaScriptEnabled: true,
            mediaPlaybackRequiresUserGesture: false,
            allowsInlineMediaPlayback: true,
            useHybridComposition: true,
            allowsBackForwardNavigationGestures: false,
            supportZoom: false,
            isInspectable: kDebugMode,
            domStorageEnabled: true,
          ),
          initialData: InAppWebViewInitialData(
            data: _htmlContent!,
            mimeType: 'text/html',
            encoding: 'utf-8',
            baseUrl: WebUri('about:blank'),
          ),
          onWebViewCreated: (controller) {
            _controller = controller;
            controller.addJavaScriptHandler(
              handlerName: 'fetchScenePayload',
              callback: (args) => _pendingScenePayload,
            );
            controller.addJavaScriptHandler(
              handlerName: 'onSceneReady',
              callback: (args) {
                if (mounted) {
                  setState(() {
                    _isReady = true;
                    _isLoading = false;
                  });
                }
                _setCameraMode(ref.read(cameraModeProvider));
                _notifyCaptureReady();
                return null;
              },
            );
          },
          onLoadStop: (controller, url) async {
            if (mounted) setState(() => _isReady = true);
            await Future.delayed(const Duration(milliseconds: 300));
            await _pushScene();
            if (mounted) {
              await _setCameraMode(ref.read(cameraModeProvider));
              _notifyCaptureReady();
            }
          },
          onConsoleMessage: (controller, msg) {
            if (kDebugMode) {
              debugPrint('3D WebView: ${msg.message}');
            }
          },
          onReceivedError: (controller, request, error) {
            if (mounted) {
              setState(() {
                _loadError = 'WebView error: ${error.description}';
                _isLoading = false;
              });
            }
          },
        ),
        if (_isLoading)
          const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Building 3D room...'),
                  ],
                ),
              ),
            ),
          ),
        if (widget.showControls) ...[
          Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: Row(
              children: [
                Expanded(
                  child: _CameraModeBar(
                    onModeSelected: (mode) {
                      ref.read(cameraModeProvider.notifier).state = mode;
                    },
                  ),
                ),
                const SizedBox(width: 6),
                Tooltip(
                  message: premiumFurniture
                      ? 'Disable premium 3D furniture'
                      : 'Enable premium 3D furniture',
                  child: Material(
                    color: premiumFurniture ? Colors.amber.shade200 : Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: () {
                        ref.read(premiumFurnitureProvider.notifier).state =
                            !premiumFurniture;
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.auto_awesome,
                          size: 18,
                          color: premiumFurniture ? Colors.black87 : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Tooltip(
                  message: showWallLabels
                      ? 'Hide wall dimension labels'
                      : 'Show wall dimension labels',
                  child: Material(
                    color: showWallLabels ? Colors.white : Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: () {
                        ref.read(showWallDimensionLabelsProvider.notifier).state =
                            !showWallLabels;
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.info_outline,
                          size: 18,
                          color: showWallLabels ? Colors.black87 : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (cameraMode == CameraMode.orbit)
            Positioned(
              right: 16,
              bottom: 80,
              child: _OrbitZoomControls(onZoom: _orbitZoom),
            ),
        ],
      ],
    );
  }
}

class _CameraModeBar extends StatelessWidget {
  const _CameraModeBar({required this.onModeSelected});

  final ValueChanged<CameraMode> onModeSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: CameraMode.values.map((mode) {
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ActionChip(
              label: Text(_label(mode)),
              onPressed: () => onModeSelected(mode),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _label(CameraMode mode) => switch (mode) {
        CameraMode.orbit => 'Orbit',
        CameraMode.top => 'Top',
        CameraMode.front => 'Front',
        CameraMode.side => 'Side',
        CameraMode.isometric => 'Isometric',
      };
}

class _OrbitZoomControls extends StatelessWidget {
  const _OrbitZoomControls({required this.onZoom});

  final Future<void> Function({required bool zoomIn}) onZoom;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ZoomButton(
          icon: Icons.add,
          tooltip: 'Zoom in',
          onPressed: () => onZoom(zoomIn: true),
        ),
        const SizedBox(height: 8),
        _ZoomButton(
          icon: Icons.remove,
          tooltip: 'Zoom out',
          onPressed: () => onZoom(zoomIn: false),
        ),
      ],
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}
