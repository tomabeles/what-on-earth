import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../shared/theme.dart';
import '../tile_cache/tile_downloader.dart';

// ---------------------------------------------------------------------------
// Layer options (TECH_SPEC §7.5, WOE-032)
// ---------------------------------------------------------------------------

/// A downloadable tile layer option shown during onboarding.
class LayerOption {
  final String layerId;
  final String displayName;
  final double estimatedSizeMb;
  final String sourceUrlTemplate;
  final String fileExtension;

  const LayerOption({
    required this.layerId,
    required this.displayName,
    required this.estimatedSizeMb,
    required this.sourceUrlTemplate,
    required this.fileExtension,
  });
}

const _layerOptions = [
  LayerOption(
    layerId: 'satellite',
    displayName: 'Satellite Imagery',
    estimatedSizeMb: 150,
    sourceUrlTemplate:
        'https://server.arcgisonline.com/ArcGIS/rest/services/'
        'World_Imagery/MapServer/tile/{z}/{y}/{x}',
    fileExtension: 'jpg',
  ),
  LayerOption(
    layerId: 'nightlights',
    displayName: 'Night Lights',
    estimatedSizeMb: 80,
    sourceUrlTemplate:
        'https://gibs.earthdata.nasa.gov/wmts/epsg3857/best/'
        'VIIRS_Black_Marble/default/2016-01-01/'
        'GoogleMapsCompatible_Level8/{z}/{y}/{x}.png',
    fileExtension: 'png',
  ),
  LayerOption(
    layerId: 'darkmatter',
    displayName: 'Dark Map',
    estimatedSizeMb: 40,
    sourceUrlTemplate:
        'https://cartodb-basemaps-a.global.ssl.fastly.net/'
        'dark_nolabels/{z}/{x}/{y}.png',
    fileExtension: 'png',
  ),
];

const _prefKey = 'downloaded_layers';

// ---------------------------------------------------------------------------
// TileDownloadStep widget (WOE-032)
// ---------------------------------------------------------------------------

/// Onboarding step 2: tile download with layer selection and progress.
///
/// Shows checkboxes for each downloadable layer, estimated sizes,
/// a download progress bar, and Skip/Next buttons.
///
/// Reference: TECH_SPEC §7.5, PRD FR-ONB-002
class TileDownloadStep extends ConsumerStatefulWidget {
  const TileDownloadStep({super.key, this.onComplete});

  /// Called when the user completes or skips this step.
  final VoidCallback? onComplete;

  @override
  ConsumerState<TileDownloadStep> createState() => TileDownloadStepState();
}

@visibleForTesting
class TileDownloadStepState extends ConsumerState<TileDownloadStep> {
  final Map<String, bool> _selected = {
    for (final l in _layerOptions) l.layerId: true,
  };

  bool _downloading = false;
  bool _done = false;
  TileDownloadProgress? _progress;
  CancelToken? _cancelToken;
  StreamSubscription<TileDownloadProgress>? _downloadSub;

  double get _totalSelectedMb => _layerOptions
      .where((l) => _selected[l.layerId] == true)
      .fold(0.0, (s, l) => s + l.estimatedSizeMb);

  @override
  void dispose() {
    _cancelToken?.cancel();
    _downloadSub?.cancel();
    super.dispose();
  }

  Future<void> _startDownload() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final downloader = TileDownloader();
    _cancelToken = CancelToken();

    final selectedLayers =
        _layerOptions.where((l) => _selected[l.layerId] == true).toList();

    if (selectedLayers.isEmpty) {
      _finish();
      return;
    }

    setState(() => _downloading = true);

    // Compute total tiles across all selected layers
    final tilesPerLayer = TileDownloader.enumerateTiles(0, 5).length;
    final totalTiles = tilesPerLayer * selectedLayers.length;
    var globalCompleted = 0;
    var globalBytes = 0;

    for (final layer in selectedLayers) {
      if (_cancelToken!.isCancelled) break;

      final stream = downloader.downloadLayer(
        layerId: layer.layerId,
        sourceUrlTemplate: layer.sourceUrlTemplate,
        documentsPath: docsDir.path,
        minZoom: 0,
        maxZoom: 5,
        ext: layer.fileExtension,
        cancelToken: _cancelToken,
      );

      await for (final p in stream) {
        if (!mounted) return;
        globalCompleted =
            (selectedLayers.indexOf(layer) * tilesPerLayer) + p.completedTiles;
        globalBytes += p.bytesDownloaded > 0 ? p.bytesDownloaded : 0;
        setState(() {
          _progress = TileDownloadProgress(
            completedTiles: globalCompleted,
            totalTiles: totalTiles,
            bytesDownloaded: globalBytes,
          );
        });
      }
    }

    if (!mounted) return;
    await _saveCompletedLayers(selectedLayers);
    setState(() => _done = true);
  }

  Future<void> _saveCompletedLayers(List<LayerOption> layers) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefKey, layers.map((l) => l.layerId).toList());
  }

  void _cancel() {
    _cancelToken?.cancel();
    _downloadSub?.cancel();
    setState(() {
      _downloading = false;
      _progress = null;
    });
  }

  void _finish() {
    widget.onComplete?.call();
  }

  void _skip() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('App may not work fully during connectivity blackouts'),
        duration: Duration(seconds: 3),
      ),
    );
    _finish();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.download_rounded, size: 48, color: tokens.hudPrimary),
          const SizedBox(height: 16),
          Text(
            'Download Map Tiles',
            style: TextStyle(
              color: tokens.hudPrimary,
              fontSize: 22,
              fontFamily: tokens.hudFontFamily,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Pre-download tiles for offline use during\ncommunication blackouts.',
            style: TextStyle(
              color: tokens.hudSecondary,
              fontSize: 13,
              fontFamily: tokens.hudFontFamily,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Layer checkboxes
          if (!_downloading && !_done) ...[
            for (final layer in _layerOptions)
              _LayerCheckbox(
                layer: layer,
                selected: _selected[layer.layerId] ?? false,
                onChanged: (v) => setState(() => _selected[layer.layerId] = v),
                tokens: tokens,
              ),
            const SizedBox(height: 8),
            Text(
              'Estimated total: ${_totalSelectedMb.toStringAsFixed(0)} MB',
              style: TextStyle(
                color: tokens.hudSecondary,
                fontSize: 12,
                fontFamily: tokens.hudFontFamily,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _startDownload,
              style: ElevatedButton.styleFrom(
                backgroundColor: tokens.fabBackground,
                foregroundColor: tokens.fabIcon,
                padding:
                    const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
              ),
              child: const Text('Download'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _skip,
              child: Text(
                'Skip',
                style: TextStyle(color: tokens.hudSecondary),
              ),
            ),
          ],

          // Download in progress
          if (_downloading && !_done) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _progress?.fraction,
              backgroundColor: tokens.borderPrimary,
              valueColor: AlwaysStoppedAnimation(tokens.hudPrimary),
            ),
            const SizedBox(height: 8),
            if (_progress != null)
              Text(
                '${_progress!.completedTiles}/${_progress!.totalTiles} tiles '
                '(${(_progress!.bytesDownloaded / 1e6).toStringAsFixed(1)} MB)',
                style: TextStyle(
                  color: tokens.hudSecondary,
                  fontSize: 12,
                  fontFamily: tokens.hudFontFamily,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _cancel,
              child: Text(
                'Cancel',
                style: TextStyle(color: tokens.hudDanger),
              ),
            ),
          ],

          // Download complete
          if (_done) ...[
            const SizedBox(height: 16),
            Icon(Icons.check_circle, size: 48, color: tokens.statusLive),
            const SizedBox(height: 12),
            Text(
              'Download complete!',
              style: TextStyle(
                color: tokens.hudPrimary,
                fontSize: 16,
                fontFamily: tokens.hudFontFamily,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _finish,
              style: ElevatedButton.styleFrom(
                backgroundColor: tokens.fabBackground,
                foregroundColor: tokens.fabIcon,
                padding:
                    const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
              ),
              child: const Text('Next →'),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Layer checkbox row
// ---------------------------------------------------------------------------

class _LayerCheckbox extends StatelessWidget {
  const _LayerCheckbox({
    required this.layer,
    required this.selected,
    required this.onChanged,
    required this.tokens,
  });

  final LayerOption layer;
  final bool selected;
  final ValueChanged<bool> onChanged;
  final AppTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: selected,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: tokens.hudPrimary,
              checkColor: tokens.surfacePrimary,
              side: BorderSide(color: tokens.hudSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              layer.displayName,
              style: TextStyle(
                color: tokens.hudPrimary,
                fontSize: 14,
                fontFamily: tokens.hudFontFamily,
              ),
            ),
          ),
          Text(
            '~${layer.estimatedSizeMb.toStringAsFixed(0)} MB',
            style: TextStyle(
              color: tokens.hudSecondary,
              fontSize: 12,
              fontFamily: tokens.hudFontFamily,
            ),
          ),
        ],
      ),
    );
  }
}
