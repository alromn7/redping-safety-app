import 'package:flutter/material.dart';

/// Preview widget to show the stylized RedPing title design
/// This demonstrates the "!" as a location pin marker
class RedPingLogoTitlePreview extends StatelessWidget {
  const RedPingLogoTitlePreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RedPing Logo Preview'),
        backgroundColor: Colors.blue[900],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Preview on dark background (like app bar)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: Colors.blue[900],
              child: Center(child: _buildStylizedTitle()),
            ),
            const SizedBox(height: 40),

            // Preview on white background
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: Colors.white,
              child: Center(child: _buildStylizedTitle(darkMode: false)),
            ),

            const SizedBox(height: 40),

            // Size comparison
            const Text(
              'Original: "RedPing Safety"',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStylizedTitle({bool darkMode = true}) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: darkMode ? Colors.white : Colors.black87,
          fontFamily: 'Roboto',
        ),
        children: [
          const TextSpan(text: 'RedP'),

          // Stylized "!" mark as location pin
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            baseline: TextBaseline.alphabetic,
            child: Transform.translate(
              offset: const Offset(0, -1),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Glow effect
                  Positioned(
                    left: -2,
                    top: -2,
                    child: Container(
                      width: 16,
                      height: 24,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFD32F2F,
                            ).withValues(alpha: 0.6),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // The "!" mark styled as a pin
                  SizedBox(
                    width: 12,
                    height: 20,
                    child: CustomPaint(painter: PingLocationPainter()),
                  ),
                ],
              ),
            ),
          ),

          const TextSpan(text: 'ng Safety'),
        ],
      ),
    );
  }
}

/// Custom painter for the ping location marker "!"
class PingLocationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color =
          const Color(0xFFD32F2F) // Red
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Draw pin-shaped "!"
    // Top teardrop/pin shape for the exclamation body
    final path = Path();
    path.moveTo(size.width / 2, 2); // Top point

    // Right curve
    path.quadraticBezierTo(
      size.width * 0.9,
      size.height * 0.3,
      size.width / 2,
      size.height * 0.6,
    );

    // Left curve back to top
    path.quadraticBezierTo(
      size.width * 0.1,
      size.height * 0.3,
      size.width / 2,
      2,
    );

    path.close();

    // Draw filled pin
    canvas.drawPath(path, paint);
    // Draw outline
    canvas.drawPath(path, strokePaint);

    // Bottom dot of "!"
    final dotRadius = size.width * 0.25;
    final dotCenter = Offset(size.width / 2, size.height * 0.85);

    canvas.drawCircle(dotCenter, dotRadius, paint);
    canvas.drawCircle(dotCenter, dotRadius, strokePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
