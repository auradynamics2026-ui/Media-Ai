import 'package:flutter/material.dart';
import '../services/backend.dart';
import 'more_screens.dart';
import 'widgets.dart';

class PhotoViewer extends StatefulWidget {
  final List<Photo> photos;
  final int index;
  const PhotoViewer({super.key, required this.photos, required this.index});
  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  late final PageController _pc = PageController(initialPage: widget.index);
  late int _cur = widget.index;
  Photo get _p => widget.photos[_cur];

  Widget _act(IconData i, String l, VoidCallback f) => TextButton.icon(onPressed: f, icon: Icon(i), label: Text(l));

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('${_cur + 1} / ${widget.photos.length}')),
        body: PageView.builder(
          controller: _pc,
          itemCount: widget.photos.length,
          onPageChanged: (i) => setState(() => _cur = i),
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.all(16),
            child: InteractiveViewer(child: PhotoTile(photo: widget.photos[i], onTap: () {})),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _act(Icons.favorite_border, 'Favorite', () => Backend.i.toggleFavorite(_p.id)),
            _act(Icons.download, 'Download', () {
              Store.downloads.value = {...Store.downloads.value, _p.id};
              snack(context, 'Saved to Downloads');
            }),
            _act(Icons.share, 'Share', () => shareLink(context, _p)),
            _act(Icons.auto_fix_high, 'Enhance', () => Navigator.push(context, MaterialPageRoute(builder: (_) => EnhancerScreen(photo: _p)))),
          ]),
        ),
      );
}
