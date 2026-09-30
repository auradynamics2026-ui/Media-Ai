import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ai_service.dart';
import '../services/backend.dart';

class FaceProfileScreen extends StatefulWidget {
  const FaceProfileScreen({super.key});
  @override
  State<FaceProfileScreen> createState() => _FaceProfileScreenState();
}

class _FaceProfileScreenState extends State<FaceProfileScreen> {
  final FaceMatcher _matcher = DemoFaceMatcher();
  XFile? _img;
  bool _busy = false, _done = false;
  int _matches = 0;

  Future<void> _pick() async {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (f != null) setState(() => _img = f);
  }

  Future<void> _create() async {
    if (_img == null) return;
    setState(() => _busy = true);
    try {
      final events = await Backend.i.events();
      final ids = <String>[];
      for (final e in events) {
        ids.addAll((await Backend.i.photos(e.id)).map((p) => p.id));
      }
      final m = await _matcher.matchPhotos(_img!.path, ids);
      for (final id in m) {
        if (!Backend.i.favorites.value.contains(id)) await Backend.i.toggleFavorite(id);
      }
      setState(() {
        _matches = m.length;
        _done = true;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Something went wrong')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Create Your Face Profile')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            GestureDetector(
              onTap: _pick,
              child: CircleAvatar(
                radius: 70,
                backgroundImage: _img == null ? null : FileImage(File(_img!.path)),
                child: _img == null ? const Icon(Icons.camera_alt, size: 36) : null,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Tips: use a clear front-facing photo, no sunglasses or masks.',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
            const Spacer(),
            if (_done)
              Text('✓ Profile created — $_matches matches added to Favorites',
                  style: const TextStyle(color: Colors.greenAccent)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _busy ? null : _pick, child: const Text('CHOOSE PHOTO')),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: (_img == null || _busy) ? null : _create,
              child: _busy
                  ? const SizedBox(
                      width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('CREATE FACE PROFILE'),
            ),
          ]),
        ),
      );
}
