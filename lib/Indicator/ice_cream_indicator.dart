import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class IceCreamIndicator extends StatelessWidget {
  final IndicatorController controller;

  const IceCreamIndicator({Key? key, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0 * (1 - controller.value),
      left: MediaQuery.of(context).size.width / 2 - 25,
      child: Transform.rotate(
        angle: pi * controller.value,
        child: Icon(Icons.icecream, size: 50, color: Colors.pinkAccent),
      ),
    );
  }
}
