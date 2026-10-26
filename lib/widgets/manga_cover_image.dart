import 'dart:io';
import 'package:flutter/material.dart';

class MangaCoverImage extends StatelessWidget {
  final String? imagePath;
  final double width;
  final double height;
  final double borderRadius;

  const MangaCoverImage({
    super.key,
    required this.imagePath,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (imagePath != null && imagePath!.isNotEmpty) {
      if (imagePath!.startsWith('http://') || imagePath!.startsWith('https://')) {
        imageWidget = Image.network(
          imagePath!,
          width: width,
          height: height,
          fit: BoxFit.cover,
          loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: width,
              height: height,
              color: Colors.grey.shade800,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
            return _buildPlaceholder();
          },
        );
      } else if (File(imagePath!).existsSync()) {
        imageWidget = Image.file(
          File(imagePath!),
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
            return _buildPlaceholder();
          },
        );
      } else {
        imageWidget = _buildPlaceholder();
      }
    } else {
      imageWidget = _buildPlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: imageWidget,
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade800,
      child: Icon(
        Icons.image_not_supported,
        size: width * 0.4,
        color: Colors.grey.shade500,
      ),
    );
  }
}
