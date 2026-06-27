// lib/core/widgets/bottom_sheet_scaffold.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

class BottomSheetScaffold extends StatelessWidget {
  const BottomSheetScaffold({super.key, required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Keyboard inset wins while typing; otherwise reserve the home-indicator
    // safe area so content never sits under it.
    final bottomInset = 30.0 + math.max(media.viewInsets.bottom, media.padding.bottom);
    return Container(
      // Cap height so a tall child scrolls instead of overflowing; the sheet
      // still shrinks to its content when the child is short.
      constraints: BoxConstraints(maxHeight: media.size.height * 0.92),
      decoration: const BoxDecoration(
        color: AppColors.sheet,
        border: Border(top: BorderSide(color: AppColors.border)),
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
      ),
      padding: EdgeInsets.fromLTRB(24, 14, 24, bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 5,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: const Color(0xFF3A3F48), // grab-handle: design-approved non-token colour
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Text(title, style: AppText.titleSection),
          const SizedBox(height: AppSpacing.lg),
          Flexible(child: SingleChildScrollView(child: child)),
        ],
      ),
    );
  }
}

Future<T?> showFluxySheet<T>(BuildContext context, {required String title, required Widget child}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x9E07090C), // overlayScrim rgba(7,9,12,0.62)
    builder: (_) => BottomSheetScaffold(title: title, child: child),
  );
}
