import 'dart:math' as math;
import 'package:flutter/material.dart';

class LayoutPainter extends CustomPainter {
  double scale;
  Color? color;
  LayoutPainter(this.scale, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    var _paint = Paint()
      ..color = color!
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawRect(Rect.fromLTRB(0, 0, 10 + 5 * scale, 10), _paint);
    if (scale < 4) {
      canvas.drawRect(
          Rect.fromLTRB(10 + 5 * scale, 0, 20 + 10 * scale, 10), _paint);
      canvas.drawRect(
          Rect.fromLTRB(20 + 5 * scale, 0, 30, 10 - 10 * scale), _paint);
    }
  }

  @override
  bool shouldRepaint(LayoutPainter oldDelegate) {
    return oldDelegate.scale != scale || oldDelegate.color != color;
  }
}

/// Multi select button.
class MultiSelectPainter extends CustomPainter {
  Color color;
  MultiSelectPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;
    final x = size.width / 2;
    final y = size.height / 2;
    var path = Path();
    path.moveTo(0, 0);
    path.lineTo(x, 0);
    path.lineTo(x, y * 2);
    path.lineTo(x * 2, y * 2);
    path.lineTo(x * 2, y);
    path.lineTo(0, y);
    path.lineTo(0, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(MultiSelectPainter oldDelegate) {
    return false;
  }
}

/// Hide listened painter.
class HideListenedPainter extends CustomPainter {
  Color? color;
  Color? backgroundColor;
  double? fraction;
  double stroke;
  HideListenedPainter(
      {this.color, this.stroke = 1.0, this.backgroundColor, this.fraction});
  @override
  void paint(Canvas canvas, Size size) {
    var _paint = Paint()
      ..color = color!
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    var _linePaint = Paint()
      ..color = backgroundColor!
      ..strokeWidth = stroke * 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    var _path = Path();

    _path.moveTo(size.width / 6, size.height * 3 / 8);
    _path.lineTo(size.width / 6, size.height * 5 / 8);
    _path.moveTo(size.width / 3, size.height / 4);
    _path.lineTo(size.width / 3, size.height * 3 / 4);
    _path.moveTo(size.width / 2, size.height / 8);
    _path.lineTo(size.width / 2, size.height * 7 / 8);
    _path.moveTo(size.width * 5 / 6, size.height * 3 / 8);
    _path.lineTo(size.width * 5 / 6, size.height * 5 / 8);
    _path.moveTo(size.width * 2 / 3, size.height / 4);
    _path.lineTo(size.width * 2 / 3, size.height * 3 / 4);

    canvas.drawPath(_path, _paint);
    if (fraction! > 0) {
      canvas.drawLine(
          Offset(size.width, size.height) / 5,
          Offset(size.width, size.height) / 5 +
              Offset(size.width, size.height) * 3 / 5 * fraction!,
          _linePaint);
    }
  }

  @override
  bool shouldRepaint(HideListenedPainter oldDelegate) {
    return oldDelegate.fraction != fraction;
  }
}

///Download button.
class DownloadPainter extends CustomPainter {
  double? fraction;
  Color? color;
  Color? progressColor;
  double? progress;
  double pauseProgress;
  double stroke;
  DownloadPainter(
      {this.fraction,
      this.color,
      this.progressColor,
      this.progress = 0,
      this.stroke = 2,
      this.pauseProgress = 0});

  @override
  void paint(Canvas canvas, Size size) {
    var _paint = Paint()
      ..color = color!
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    var _circlePaint = Paint()
      ..color = color!.withAlpha(70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    var _progressPaint = Paint()
      ..color = progressColor!
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    var width = size.width;
    var height = size.height;
    var center = Offset(size.width / 2, size.height / 2);
    if (pauseProgress == 0 && progress! < 1) {
      canvas.drawLine(
          Offset(width / 2, 4), Offset(width / 2, height * 4 / 5), _paint);
      canvas.drawLine(Offset(width / 4, height / 2),
          Offset(width / 2, height * 4 / 5), _paint);
      canvas.drawLine(Offset(width * 3 / 4, height / 2),
          Offset(width / 2, height * 4 / 5), _paint);
    }

    if (fraction == 0) {
      canvas.drawLine(
          Offset(width / 5, height), Offset(width * 4 / 5, height), _paint);
    } else if (progress! < 1) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: width / 2),
          math.pi / 2, math.pi * fraction!, false, _circlePaint);
      canvas.drawArc(Rect.fromCircle(center: center, radius: width / 2),
          math.pi / 2, -math.pi * fraction!, false, _circlePaint);
    }

    if (progress == 1) {
      canvas.drawLine(Offset(width / 5, height * 9 / 10),
          Offset(width * 4 / 5, height * 9 / 10), _progressPaint);
      canvas.drawLine(Offset(width / 5, height * 5 / 10),
          Offset(width * 2 / 5, height * 7 / 10), _progressPaint);
      canvas.drawLine(Offset(width * 4 / 5, height * 3 / 10),
          Offset(width * 2 / 5, height * 7 / 10), _progressPaint);
    }

    if (fraction == 1 && progress! < 1) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: width / 2),
          -math.pi / 2, math.pi * 2 * progress!, false, _progressPaint);
    }

    if (pauseProgress > 0) {
      canvas.drawLine(
          Offset(width / 5 + height * 3 * pauseProgress / 20,
              height / 2 - height * pauseProgress / 5),
          Offset(width / 2 - height * 3 * pauseProgress / 20,
              height * 4 / 5 - height * pauseProgress / 10),
          _paint);
      canvas.drawLine(
          Offset(width * 4 / 5 - height * 3 * pauseProgress / 20,
              height / 2 - height * pauseProgress / 5),
          Offset(width / 2 + height * 3 * pauseProgress / 20,
              height * 4 / 5 - height * pauseProgress / 10),
          _paint);
    }
  }

  @override
  bool shouldRepaint(DownloadPainter oldDelegate) {
    return oldDelegate.fraction != fraction ||
        oldDelegate.progress != progress ||
        oldDelegate.pauseProgress != pauseProgress;
  }
}
