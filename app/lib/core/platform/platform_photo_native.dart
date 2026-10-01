import 'dart:io';
import 'package:flutter/material.dart';

Widget platformPhoto(
  String source, {
  BoxFit? fit,
  double? width,
  double? height,
  ImageErrorWidgetBuilder? errorBuilder,
}) {
  if (source.startsWith('/') || source.startsWith('file://')) {
    return Image.file(
      File(
        source.startsWith('file:') ? Uri.parse(source).toFilePath() : source,
      ),
      fit: fit,
      width: width,
      height: height,
      errorBuilder: errorBuilder,
    );
  }
  return Image.network(
    source,
    fit: fit,
    width: width,
    height: height,
    errorBuilder: errorBuilder,
  );
}
