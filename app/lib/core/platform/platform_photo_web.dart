import 'package:flutter/material.dart';

Widget platformPhoto(
  String source, {
  BoxFit? fit,
  double? width,
  double? height,
  ImageErrorWidgetBuilder? errorBuilder,
}) => Image.network(
  source,
  fit: fit,
  width: width,
  height: height,
  errorBuilder: errorBuilder,
);
