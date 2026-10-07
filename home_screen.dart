import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/models.dart';
import '../services/catalog_repository.dart';
import '../services/try_on_service.dart';
import '../state/try_on_state.dart';
import '../widgets/glass.dart';
import 'viewer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Garment>> _catalog;
  final _picker = ImagePicker();
  String? _category;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _catalog = context.read<CatalogRepository>().loadCatalog();

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final x = await _picker.pickImage(source: source, maxWidth: 2048, imageQuality: 90);
      if (x != null && mounted) context.read<TryOnState>().setModelImage(File(x.path));
    } catch (e) {
      _toast('Could not open ${source == ImageSource.camera ? 'camera' : 'gallery'}: $e');
    }
  }

  Future<void> _tryOn() async {
    final state = context.read<TryOnState>();
    if (!state.canTryOn) {
      _toast(state.modelImage == null ? 'Add your photo first' : 'Pick a garment first');
      return;
    }
    final ok = await state.runTryOn(context.read<TryOnService>());
    if (!mounted) return;
    if (ok) {
      Navigator.push(
        context,
        fadeRoute(ViewerScreen(before: state.modelImage!, after: state.latestOutput!)),
      );
    } else {
      _toast(state.error ?? 'Try-on failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TryOnState>();
    return Scaffold(
      extendBody: true,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _TryOnButton(ready: state.canTryOn, onPressed: _tryOn),
      body: GradientBackdrop(
        child: Stack(
          children: [
            FutureBuilder<List<Garment>>(
              future: _catalog,
              builder: (context, snap) => CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _appBar(state),
                  SliverToBoxAdapter(child: _captureCard(state)),
                  ..._catalogSlivers(snap, state),
                ],
              ),
            ),
            if (state.isBusy) const Positioned.fill(child: _LoadingOverlay()),
          ],
        ),
      ),
    );
  }

  Widget _appBar(TryOnState state) => SliverAppBar(
        pinned: true,
        stretch: true,
        expandedHeight: 300,
        backgroundColor: AppColors.bgTop.withAlpha(200),
        surfaceTintColor: Colors.transparent,
        actions: [
          if (state.modelImage != null)
            IconButton(
              tooltip: 'Remove photo',
              icon: const Icon(Icons.close_rounded),
              onPressed: () => state.setModelImage(null),
            ),
        ],
        flexibleSpace: FlexibleSpaceBar(
          stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle],
          title: const Text('Virtual Try-On', style: TextStyle(fontWeight: FontWeight.w800)),
          background: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Stack(
              key: ValueKey(state.modelImage?.path),
              fit: StackFit.expand,
              children: [
                if (state.modelImage != null)
                  Image.file(state.modelImage!, fit: BoxFit.cover)
                else
                  Center(child: Icon(Icons.person_outline_rounded, size: 110, color: Colors.white.withAlpha(50))),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, AppColors.bgTop.withAlpha(230)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _captureCard(TryOnState state) => Padding(
        padding: const EdgeInsets.all(16),
        child: GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                state.modelImage == null ? 'Full-body, facing the camera works best.' : 'Looking good - pick a garment below.',
                style: TextStyle(color: Colors.white.withAlpha(160)),
              ),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: _ActionButton(Icons.photo_camera_rounded, 'Camera', () => _pick(ImageSource.camera))),
                const SizedBox(width: 12),
                Expanded(child: _ActionButton(Icons.photo_library_rounded, 'Gallery', () => _pick(ImageSource.gallery))),
              ]),
            ],
          ),
        ),
      );

  List<Widget> _catalogSlivers(AsyncSnapshot<List<Garment>> snap, TryOnState state) {
    if (snap.connectionState != ConnectionState.done) {
      return const [
        SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator()))),
      ];
    }
    if (snap.hasError || (snap.data ?? []).isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(children: [
              const Text('Could not load the catalog.'),
              TextButton(onPressed: () => setState(_load), child: const Text('Retry')),
            ]),
          ),
        ),
      ];
    }
    final garments = snap.data!;
    final categories = garments.map((g) => g.category).toSet().toList();
    final active = categories.contains(_category) ? _category! : categories.first;
    final visible = garments.where((g) => g.category == active).toList();

    return [
      SliverPersistentHeader(
        pinned: true,
        delegate: _ChipsHeader(
          ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              for (final c in categories)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(c[0].toUpperCase() + c.substring(1)),
                    selected: c == active,
                    showCheckmark: false,
                    selectedColor: AppColors.accent.withAlpha(200),
                    backgroundColor: Colors.white.withAlpha(25),
                    side: BorderSide.none,
                    onSelected: (_) => setState(() => _category = c),
                  ),
                ),
            ],
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: .75,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          delegate: SliverChildBuilderDelegate(
            (_, i) {
              final g = visible[i];
              return _GarmentTile(
                key: ValueKey('${g.id}_$active'),
                garment: g,
                index: i,
                selected: state.selectedGarment?.id == g.id,
                onTap: () => state.selectGarment(g),
              );
            },
            childCount: visible.length,
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 120)),
    ];
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton(this.icon, this.label, this.onTap);

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      );
}

class _ChipsHeader extends SliverPersistentHeaderDelegate {
  final Widget child;
  _ChipsHeader(this.child);

  @override
  double get minExtent => 64;
  @override
  double get maxExtent => 64;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(color: AppColors.bgTop.withAlpha(110), child: child),
        ),
      );

  @override
  bool shouldRebuild(covariant _ChipsHeader old) => true;
}

class _GarmentTile extends StatelessWidget {
  final Garment garment;
  final int index;
  final bool selected;
  final VoidCallback onTap;
  const _GarmentTile({super.key, required this.garment, required this.index, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + index * 70),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 24 * (1 - v)), child: child),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: selected ? AppColors.accent : Colors.white.withAlpha(30),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(21),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  garment.url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.white.withAlpha(20),
                    child: const Icon(Icons.checkroom_rounded, size: 48),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        color: Colors.black.withAlpha(90),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Text(garment.name,
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: AnimatedScale(
                    scale: selected ? 1 : 0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.elasticOut,
                    child: const CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.accent,
                      child: Icon(Icons.check_rounded, size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TryOnButton extends StatelessWidget {
  final bool ready;
  final VoidCallback onPressed;
  const _TryOnButton({required this.ready, required this.onPressed});

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
        opacity: ready ? 1 : .6,
        duration: const Duration(milliseconds: 250),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Material(
              color: AppColors.accent.withAlpha(ready ? 225 : 100),
              child: InkWell(
                onTap: onPressed,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.auto_awesome_rounded),
                    SizedBox(width: 10),
                    Text('Try on', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  ]),
                ),
              ),
            ),
          ),
        ),
      );
}

/// Stays up for the whole processTryOn call (incl. B's silent fallback).
class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 300),
        builder: (_, v, child) => Opacity(opacity: v, child: child),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            color: Colors.black.withAlpha(110),
            child: const Center(
              child: GlassCard(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  CircularProgressIndicator(color: AppColors.accent),
                  SizedBox(height: 20),
                  Text('Styling your look...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ),
        ),
      );
}
