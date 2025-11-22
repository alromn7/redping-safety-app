import 'package:flutter/material.dart';
import 'widgets/redping_logo_title_preview.dart';

void main() {
  runApp(const RedPingLogoPreviewApp());
}

class RedPingLogoPreviewApp extends StatelessWidget {
  const RedPingLogoPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RedPing Logo Preview',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const RedPingLogoTitlePreview(),
      debugShowCheckedModeBanner: false,
    );
  }
}
