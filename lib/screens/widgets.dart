import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/backend.dart';
import 'photo_viewer.dart';

class PhotoTile extends StatelessWidget {
  final Photo photo;
  final VoidCallback onTap;
  const PhotoTile({super.key, required this.photo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hue = (photo.id.hashCode % 360).abs().toDouble();
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(fit: StackFit.expand, children: [
          photo.url.isEmpty
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      HSVColor.fromAHSV(1, hue, .6, .5).toColor(),
                      HSVColor.fromAHSV(1, (hue + 60) % 360, .7, .3).toColor(),
                    ]),
                  ),
                  child: const Icon(Icons.image, color: Colors.white24, size: 40))
              : Image.network(photo.url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
          Positioned(
            top: 6,
            right: 6,
            child: ValueListenableBuilder<Set<String>>(
              valueListenable: Backend.i.favorites,
              builder: (_, favs, __) => GestureDetector(
                onTap: () => Backend.i.toggleFavorite(photo.id),
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.black54,
                  child: Icon(favs.contains(photo.id) ? Icons.favorite : Icons.favorite_border,
                      size: 16,
                      color: favs.contains(photo.id) ? Colors.pinkAccent : Colors.white),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class PhotoGrid extends StatelessWidget {
  final List<Photo> photos;
  const PhotoGrid(this.photos, {super.key});
  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) return const Center(child: Text('No photos yet'));
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 180, mainAxisSpacing: 8, crossAxisSpacing: 8),
      itemCount: photos.length,
      itemBuilder: (_, i) => PhotoTile(
        photo: photos[i],
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => PhotoViewer(photos: photos, index: i))),
      ),
    );
  }
}

class CardBox extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const CardBox({super.key, required this.child, this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: AppColors.card,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(14)),
          child: child,
        ),
      );
}
