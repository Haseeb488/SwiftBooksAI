import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class ReceiptImageViewerScreen extends StatefulWidget {
  final String imageUrls; // comma separated URLs

  const ReceiptImageViewerScreen({
    super.key,
    required this.imageUrls,
  });

  @override
  State<ReceiptImageViewerScreen> createState() => _ReceiptImageViewerScreenState();
}

class _ReceiptImageViewerScreenState extends State<ReceiptImageViewerScreen> {
  late List<String> urls;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    super.initState();

    // 1. Split and trim the raw string
    List<String> rawUrls = widget.imageUrls.split(",").map((e) => e.trim()).toList();

    // 2. Find the base URL path from the first valid full URL
    String baseUrl = "";
    for (String url in rawUrls) {
      if (url.startsWith("http://") || url.startsWith("https://")) {
        // Extracts everything up to the last slash: "https://.../images/1220/"
        baseUrl = url.substring(0, url.lastIndexOf("/") + 1);
        break;
      }
    }

    // 3. Rebuild the list, fixing partial paths
    urls = rawUrls.map((url) {
      if (url.startsWith("http://") || url.startsWith("https://")) {
        return url; // It's already a full URL
      } else {
        return "$baseUrl$url"; // Append the missing base URL path
      }
    }).toList();

    print("Fixed Image URLs: $urls");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Swipable Image Viewer
          PhotoViewGallery.builder(
            itemCount: urls.length,
            builder: (context, index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(urls[index]),
                // backgroundDecoration: const BoxDecoration(color: Colors.black),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3,
              );
            },
            loadingBuilder: (context, event) => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
            onPageChanged: (index) {
              setState(() {
                currentIndex = index;
              });
            },
          ),

          // Close Button
          Positioned(
            top: 40,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black.withOpacity(0.6),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Page Indicator
          if (urls.length > 1)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  "${currentIndex + 1} / ${urls.length}",
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
