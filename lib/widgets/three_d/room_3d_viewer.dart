import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

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
import '../../providers/walkthrough_settings_provider.dart';
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

  Future<void> _pushWalkthroughSettings() async {
    if (_controller == null) return;
    final settings = ref.read(walkthroughSettingsProvider);
    await _controller!.evaluateJavascript(
      source:
          'setWalkthroughSettings({eyeHeightFt:${settings.clampedEyeHeightFt}});',
    );
  }

  Future<void> _syncWalkInputs({
    bool forward = false,
    bool backward = false,
    bool left = false,
    bool right = false,
  }) async {
    if (_controller == null) return;
    await _controller!.evaluateJavascript(
      source:
          'setWalkInputs({forward:$forward,backward:$backward,left:$left,right:$right});',
    );
  }

  Future<void> _releaseWalkInputs() async {
    await _syncWalkInputs();
    await _setWalkRunActive(false);
  }

  Future<void> _setWalkRunActive(bool active) async {
    if (_controller == null) return;
    await _controller!.evaluateJavascript(
      source: 'setWalkRunActive(${active ? 'true' : 'false'});',
    );
  }

  Future<double> _getWalkthroughHeading() async {
    if (_controller == null) return 0;
    try {
      final result = await _controller!.evaluateJavascript(
        source: 'getWalkthroughHeading();',
      );
      return double.tryParse(result?.toString() ?? '') ?? 0;
    } catch (_) {
      return 0;
    }
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

    ref.listen(cameraModeProvider, (previous, next) {
      if (_isReady) {
        _setCameraMode(next);
        if (next != CameraMode.walkthrough) {
          unawaited(_releaseWalkInputs());
        }
      }
    });

    ref.listen(showWallDimensionLabelsProvider, (_, _) {
      if (_isReady) _pushScene();
    });

    ref.listen(premiumFurnitureProvider, (_, _) {
      if (_isReady) _pushScene();
    });

    ref.listen(walkthroughSettingsProvider, (_, _) {
      if (_isReady) _pushWalkthroughSettings();
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
                _pushWalkthroughSettings();
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
              await Future.delayed(const Duration(milliseconds: 150));
              await _setCameraMode(ref.read(cameraModeProvider));
              await _pushWalkthroughSettings();
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
          if (cameraMode == CameraMode.walkthrough) ...[
            Positioned(
              top: 56,
              right: 12,
              child: _WalkthroughCompass(
                headingProvider: _getWalkthroughHeading,
              ),
            ),
            Positioned(
              right: 16,
              bottom: 24,
              child: _WalkthroughMovePad(
                onSync: _syncWalkInputs,
                onRunChanged: _setWalkRunActive,
              ),
            ),
            Positioned(
              left: 12,
              bottom: 24,
              child: _WalkthroughModeBadge(),
            ),
          ],
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
        CameraMode.walkthrough => 'Walk',
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

class _WalkthroughModeBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_walk, color: Colors.white, size: 16),
            SizedBox(width: 6),
            Text(
              'Walkthrough',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalkthroughCompass extends StatefulWidget {
  const _WalkthroughCompass({required this.headingProvider});

  final Future<double> Function() headingProvider;

  @override
  State<_WalkthroughCompass> createState() => _WalkthroughCompassState();
}

class _WalkthroughCompassState extends State<_WalkthroughCompass> {
  Timer? _timer;
  double _heading = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 80), (_) async {
      final heading = await widget.headingProvider();
      if (mounted) setState(() => _heading = heading);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -_heading * math.pi / 180,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: const SizedBox(
          width: 52,
          height: 52,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(top: 6, child: Text('N', style: TextStyle(color: Colors.white70, fontSize: 10))),
              Positioned(right: 8, child: Text('E', style: TextStyle(color: Colors.white38, fontSize: 9))),
              Positioned(bottom: 6, child: Text('S', style: TextStyle(color: Colors.white38, fontSize: 9))),
              Positioned(left: 8, child: Text('W', style: TextStyle(color: Colors.white38, fontSize: 9))),
              Icon(Icons.navigation, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalkthroughMovePad extends StatefulWidget {
  const _WalkthroughMovePad({
    required this.onSync,
    required this.onRunChanged,
  });

  final Future<void> Function({
    bool forward,
    bool backward,
    bool left,
    bool right,
  }) onSync;
  final Future<void> Function(bool active) onRunChanged;

  @override
  State<_WalkthroughMovePad> createState() => _WalkthroughMovePadState();
}

class _WalkthroughMovePadState extends State<_WalkthroughMovePad> {
  bool _forward = false;
  bool _backward = false;
  bool _left = false;
  bool _right = false;
  bool _runActive = false;
  Timer? _runTimer;

  @override
  void dispose() {
    _runTimer?.cancel();
    unawaited(widget.onSync());
    super.dispose();
  }

  void _pushInputs() {
    unawaited(widget.onSync(
      forward: _forward,
      backward: _backward,
      left: _left,
      right: _right,
    ));
  }

  void _setDirection({
    bool? forward,
    bool? backward,
    bool? left,
    bool? right,
  }) {
    setState(() {
      if (forward != null) _forward = forward;
      if (backward != null) _backward = backward;
      if (left != null) _left = left;
      if (right != null) _right = right;
    });
    _pushInputs();
  }

  void _clearDirection(String direction) {
    switch (direction) {
      case 'forward':
        _setDirection(forward: false);
        if (_runActive) {
          _runActive = false;
          unawaited(widget.onRunChanged(false));
        }
        _runTimer?.cancel();
      case 'backward':
        _setDirection(backward: false);
      case 'left':
        _setDirection(left: false);
      case 'right':
        _setDirection(right: false);
    }
  }

  void _pressDirection(String direction) {
    switch (direction) {
      case 'forward':
        _setDirection(forward: true);
        _runTimer?.cancel();
        _runTimer = Timer(const Duration(milliseconds: 450), () {
          if (!mounted || !_forward) return;
          _runActive = true;
          unawaited(widget.onRunChanged(true));
        });
      case 'backward':
        _setDirection(backward: true);
      case 'left':
        _setDirection(left: true);
      case 'right':
        _setDirection(right: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WalkPadButton(
          icon: Icons.keyboard_arrow_up,
          onPress: () => _pressDirection('forward'),
          onRelease: () => _clearDirection('forward'),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _WalkPadButton(
              icon: Icons.keyboard_arrow_left,
              onPress: () => _pressDirection('left'),
              onRelease: () => _clearDirection('left'),
            ),
            const SizedBox(width: 48),
            _WalkPadButton(
              icon: Icons.keyboard_arrow_right,
              onPress: () => _pressDirection('right'),
              onRelease: () => _clearDirection('right'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _WalkPadButton(
          icon: Icons.keyboard_arrow_down,
          onPress: () => _pressDirection('backward'),
          onRelease: () => _clearDirection('backward'),
        ),
      ],
    );
  }
}

class _WalkPadButton extends StatelessWidget {
  const _WalkPadButton({
    required this.icon,
    required this.onPress,
    required this.onRelease,
  });

  final IconData icon;
  final VoidCallback onPress;
  final VoidCallback onRelease;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => onPress(),
      onTapUp: (_) => onRelease(),
      onTapCancel: onRelease,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(icon, color: Colors.black87, size: 30),
        ),
      ),
    );
  }
}
