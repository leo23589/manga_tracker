import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/manga.dart';
import '../services/extension_server_service.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    // Wait a brief frame for providers
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final collection = context.read<MangaCollectionData>();
    final serverService = context.read<ExtensionServerService>();

    // Start background sync server
    await serverService.startServer(collection);

    // Give smooth transition
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          pageBuilder: (context, animation, secondaryAnimation) => const MainScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withAlpha((255 * 0.2).round()),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF6366F1), width: 2),
                ),
                child: const Icon(
                  Icons.auto_stories,
                  size: 50,
                  color: Color(0xFF818CF8),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Manga Tracker",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Color(0xFFF3F4F6),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Your Personal Manga Library",
                style: TextStyle(fontSize: 14, color: Colors.white54),
              ),
              const SizedBox(height: 36),
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Color(0xFF6366F1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
