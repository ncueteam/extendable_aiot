import 'dart:math';

import 'package:flutter/material.dart';

class Airconditioner extends StatefulWidget {
  final String title;
  final int value;
  final bool status;
  final String roomName;
  const Airconditioner({
    super.key,
    required this.title,
    required this.value,
    required this.status,
    required this.roomName,
  });

  @override
  State<Airconditioner> createState() => _AirconditionerState();
}

class _AirconditionerState extends State<Airconditioner> {
  late int _currentTemp = widget.value;
  int _angle = 0;

  void _updateTemperature(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    final radians = atan2(dy, dx);
    final degrees = radians * 180 / pi;
    final fixedDegrees = (degrees + 360) % 360;

    // 只允許從 10°~60°範圍內 (跟圖片一致)
    if (fixedDegrees >= 15 && fixedDegrees <= 40) {
      setState(() {
        _angle = radians;
        _currentTemp = widget.value;
        // 把角度對應到溫度 (16°C到30°C之間)
      });
    }
  }

  // 開關狀態
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          const SizedBox(height: 50),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('連接開關', style: TextStyle(fontSize: 20)),
              ),
              Switch(
                value: widget.status,
                onChanged: (value) {
                  setState(() {
                    //widget.status = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onPanUpdate: (details) {
              RenderBox box = context.findRenderObject() as RenderBox;
              Offset localPos = box.globalToLocal(details.globalPosition);
              _updateTemperature(localPos, Size(box.size.width, 300));
            },
            child: SizedBox(
              width: double.infinity,
              height: 300,
              child: CustomPaint(
                painter: TemperaturePainter(
                  currentTemp: _currentTemp,
                  angle: _angle,
                  isSwitchOn: widget.status,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TemperaturePainter extends CustomPainter {
  final int currentTemp;
  final int angle;
  final bool isSwitchOn;

  TemperaturePainter({
    required this.currentTemp,
    required this.angle,
    required this.isSwitchOn,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = 100.0;

    // 外圈背景
    final bgPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10;
    canvas.drawCircle(center, radius, bgPaint);

    // 內圈溫度區域
    final fillPaint =
        Paint()
          ..color = isSwitchOn ? Colors.blue : Colors.grey
          ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 10, fillPaint);

    // 畫小刻度
    final tickPaint =
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2;
    for (int i = 10; i <= 60; i += 10) {
      final rad = (i - 90) * pi / 180;
      final start = Offset(
        center.dx + (radius - 5) * cos(rad),
        center.dy + (radius - 5) * sin(rad),
      );
      final end = Offset(
        center.dx + radius * cos(rad),
        center.dy + radius * sin(rad),
      );
      canvas.drawLine(start, end, tickPaint);
    }

    // 畫溫度文字
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${currentTemp.toInt()}°C',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - 40),
    );

    // 畫小字"設定溫度"
    final smallTextPainter = TextPainter(
      text: const TextSpan(
        text: '設定溫度',
        style: TextStyle(color: Colors.white70, fontSize: 16),
      ),
      textDirection: TextDirection.ltr,
    );
    smallTextPainter.layout();
    smallTextPainter.paint(
      canvas,
      Offset(center.dx - smallTextPainter.width / 2, center.dy + 10),
    );
  }

  @override
  bool shouldRepaint(covariant TemperaturePainter oldDelegate) {
    return oldDelegate.currentTemp != currentTemp ||
        oldDelegate.angle != angle ||
        oldDelegate.isSwitchOn != isSwitchOn;
  }
}
