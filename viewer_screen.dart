import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

import '../core/theme.dart';
import '../models/models.dart';
import '../widgets/glass.dart';

/// WS-A3: Before vs After viewer + download.
/// Two modes: side-by-side, and an opacity-slider overlay
/// (slider 0 = Before only, 1 = After fully visible).
class ViewerScreen extends StatefulWidget {
  final File before;
  final ImageResult after;
  const ViewerScreen({super.key, required this.before, required this.after});

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  int _mode = 0; // 0 side-by-side, 1 overlay
  double _alpha = .5;
  bool _saving = false;

  void _toast(String m) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m), behavior: SnackBarBehavior.floating));

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      if (!await Gal.hasAccess() && !await Gal.requestAccess()) {
        throw 'Gallery permission denied';
      }
      final dir = await getTemporaryDirectory();
      final f = File('${dir.path}/tryon_${DateTime.now().millisecondsSinceEpoch}.${widget.after.extension}');
      await f.writeAsBytes(widget.after.bytes);
      await Gal.putImage(f.path);
      if (mounted) _toast('Saved to your gallery');
    } catch (e) {
      if (mounted) _toast('Could not save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: TextStyle(color: Colors.white.withAlpha(180), fontWeight: FontWeight.w700, letterSpacing: 1.2)),
      );

  Widget _photo(ImageProvider p) => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image(image: p, fit: BoxFit.cover, width: double.infinity, height: double.infinity, gaplessPlayback: true),
      );

  Widget _sideBySide() => Padding(
        key: const ValueKey('side'),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Expanded(child: Column(children: [_label('BEFORE'), Expanded(child: _photo(FileImage(widget.before)))])),
          const SizedBox(width: 12),
          Expanded(child: Column(children: [_label('AFTER'), Expanded(child: _photo(MemoryImage(widget.after.bytes)))])),
        ]),
      );

  Widget _overlay() => Padding(
        key: const ValueKey('overlay'),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(children: [
          _label('BEFORE  ->  AFTER'),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(fit: StackFit.expand, children: [
                    Image.file(widget.before, fit: BoxFit.cover),
                    Opacity(opacity: _alpha, child: Image.memory(widget.after.bytes, fit: BoxFit.cover)),
                  ]),
                ),
              ),
            ),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Before vs After', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: GradientBackdrop(
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: SegmentedButton<int>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 0, icon: Icon(Icons.vertical_split_rounded), label: Text('Side by side')),
                  ButtonSegment(value: 1, icon: Icon(Icons.layers_rounded), label: Text('Overlay')),
                ],
                selected: {_mode},
                onSelectionChanged: (s) => setState(() => _mode = s.first),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _mode == 0 ? _sideBySide() : _overlay(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: GlassCard(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    child: _mode == 1
                        ? Row(children: [
                            const Text('Before'),
                            Expanded(
                              child: Slider(
                                value: _alpha,
                                activeColor: AppColors.accent,
                                onChanged: (v) => setState(() => _alpha = v),
                              ),
                            ),
                            const Text('After'),
                          ])
                        : const SizedBox(width: double.infinity),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                      ),
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.download_rounded),
                      label: const Text('Download result', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
