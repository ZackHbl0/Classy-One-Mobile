import 'dart:io';
import 'package:image/image.dart';

void main() {
  final imageFile = File('assets/images/app_icon.jpg');
  final imageBytes = imageFile.readAsBytesSync();
  final image = decodeImage(imageBytes);

  if (image == null) {
    print('Failed to decode image');
    return;
  }

  int minX = image.width;
  int minY = image.height;
  int maxX = 0;
  int maxY = 0;

  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final pixel = image.getPixel(x, y);
      if (pixel.r < 245 || pixel.g < 245 || pixel.b < 245) {
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    }
  }

  if (minX > maxX || minY > maxY) {
    print('Could not find bounding box');
    return;
  }

  final cropped = copyCrop(image, x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1);

  int maxDim = cropped.width > cropped.height ? cropped.width : cropped.height;
  // Make logo 55% of the total canvas to match Play Store aesthetics and Adaptive Icon mask
  int newSize = (maxDim / 0.55).round();

  final finalImage = Image(width: newSize, height: newSize);
  fill(finalImage, color: ColorRgb8(255, 255, 255));

  int dstX = (newSize - cropped.width) ~/ 2;
  int dstY = (newSize - cropped.height) ~/ 2;
  compositeImage(finalImage, cropped, dstX: dstX, dstY: dstY);

  final pngBytes = encodePng(finalImage);
  File('assets/images/app_icon_adaptive.png').writeAsBytesSync(pngBytes);
  print('Cropped and padded image saved to assets/images/app_icon_adaptive.png');
}
