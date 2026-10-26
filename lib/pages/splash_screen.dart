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
  double _loadingProgress = 0.0;
  String _statusMessage = "Loading library...";

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    // Phase 1: Load Local Library (0% -> 30%)
    setState(() {
      _loadingProgress = 0.2;
      _statusMessage = "Loading library data...";
    });
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;
    final collection = context.read<MangaCollectionData>();
    final serverService = context.read<ExtensionServerService>();

    // Phase 2: Start Extension Server (30% -> 70%)
    setState(() {
      _loadingProgress = 0.6;
      _statusMessage = "Starting extension server...";
    });
    await serverService.startServer(collection);
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    // Phase 3: Finalize (70% -> 100%)
    setState(() {
      _loadingProgress = 1.0;
      _statusMessage = "Ready!";
    });
    await Future.delayed(const Duration(milliseconds: 300));

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
    final int percent = (_loadingProgress * 100).toInt();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 2D Orange/Dark Cat with belly up
              FadeTransition(
                opacity: _fadeAnimation,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/images/orange_cat.png',
                    width: 180,
                    height: 180,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                "Manga Tracker",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Color(0xFFF3F4F6),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Your Personal Manga Library",
                style: TextStyle(fontSize: 14, color: Colors.white54),
              ),
              const SizedBox(height: 36),

              // Progress Bar & Percentage
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _statusMessage,
                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    "$percent%",
                    style: const TextStyle(
                      color: Color(0xFF818CF8),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _loadingProgress,
                  minHeight: 10,
                  backgroundColor: const Color(0xFF1E1E28),
                  color: const Color(0xFF6366F1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
