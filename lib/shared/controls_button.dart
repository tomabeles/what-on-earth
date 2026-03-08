import 'package:flutter/material.dart';

import 'layer_control_panel.dart';
import 'theme.dart';

/// Rectangular pill button "^ Controls" in bottom-left of AR View.
/// Tapping toggles the [LayerControlPanel] overlay.
///
/// Reference: UI_SPEC SS3.2
class ControlsButton extends StatefulWidget {
  const ControlsButton({
    super.key,
    this.isMapMode = false,
  });

  /// When true, the Camera toggle row is hidden in the layer panel.
  final bool isMapMode;

  @override
  State<ControlsButton> createState() => _ControlsButtonState();
}

class _ControlsButtonState extends State<ControlsButton> {
  bool _isPanelOpen = false;

  void _toggle() {
    setState(() => _isPanelOpen = !_isPanelOpen);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Layer control panel (above button)
        if (_isPanelOpen)
          LayerControlPanel(
            isMapMode: widget.isMapMode,
            onClose: () => setState(() => _isPanelOpen = false),
          ),
        if (_isPanelOpen) const SizedBox(height: 8),
        // Controls button
        GestureDetector(
          onTap: _toggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: tokens.surfaceOverlay,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '\u25B4 Controls',
              style: TextStyle(
                color: tokens.hudPrimary,
                fontFamily: tokens.hudFontFamily,
                fontSize: tokens.hudFontSize,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
