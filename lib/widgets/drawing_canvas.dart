import 'package:flutter/material.dart';

import '../controllers/drawing_controller.dart';
import '../painters/drawing_painter.dart';

class DrawingCanvas extends StatelessWidget {
  final DrawingController controller;
  final double zoom;

  const DrawingCanvas({super.key, required this.controller, this.zoom = 1.0});

  Offset _toPaperPosition(Offset position, Size size) {
    final scale = size.width / DrawingPainter.basePageWidth;

    return Offset(position.dx / scale, position.dy / scale);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return IgnorePointer(
          ignoring: controller.textMode,

          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);

              return Listener(
                behavior: HitTestBehavior.opaque,

                onPointerDown: (event) {
                  controller.start(_toPaperPosition(event.localPosition, size));
                },

                onPointerMove: (event) {
                  controller.update(
                    _toPaperPosition(event.localPosition, size),
                  );
                },

                onPointerUp: (_) {
                  controller.end();
                },

                onPointerCancel: (_) {
                  controller.end();
                },

                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: DrawingPainter(controller, zoom: zoom),

                    isComplex: true,
                    willChange: true,

                    child: const SizedBox.expand(),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
