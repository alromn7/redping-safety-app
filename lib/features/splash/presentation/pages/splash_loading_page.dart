import 'package:flutter/material.dart';

class SplashLoadingPage extends StatelessWidget {
  const SplashLoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              SizedBox(height: 40),
              FlutterLogo(size: 80),
              SizedBox(height: 24),
              Text(
                'Loading RedPing...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              CircularProgressIndicator(color: Colors.red),
            ],
          ),
        ),
      ),
    );
  }
}
