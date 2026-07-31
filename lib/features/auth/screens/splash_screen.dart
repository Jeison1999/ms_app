import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _fadeOutController;

  late Animation<double> _logoOpacity;
  late Animation<double> _logoPosition;
  late Animation<double> _logoScale;

  late Animation<double> _textOpacity;
  late Animation<double> _textPosition;

  late Animation<double> _backdropOpacity;
  late Animation<double> _backdropPosition;

  bool _imageLoaded = false;
  bool _authCheckRequested = false;

  // URL optimizada con transformaciones de Cloudinary
  final String _imageUrl =
      'https://res.cloudinary.com/dsm6diilz/image/upload/f_auto,q_auto,w_400/v1771519478/logoms2_exyhn7.png';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadImageAndStart();
    });
  }

  void _initializeAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeOutController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    _logoPosition = Tween<double>(
      begin: -20.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOut));

    _logoScale = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOut));

    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    _textPosition = Tween<double>(
      begin: 10.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    _backdropOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeOutController, curve: Curves.easeOut),
    );

    _backdropPosition = Tween<double>(begin: 0.0, end: -6.0).animate(
      CurvedAnimation(parent: _fadeOutController, curve: Curves.easeOut),
    );
  }

  Future<void> _preloadImageAndStart() async {
    try {
      await precacheImage(
        NetworkImage(_imageUrl),
        context,
      ).timeout(const Duration(seconds: 3));
    } catch (_) {
      // Si falla la red, igual seguimos (Image.network tiene errorBuilder).
    }

    if (!mounted) return;

    setState(() {
      _imageLoaded = true;
    });
    await Future.delayed(const Duration(milliseconds: 50));
    if (mounted) {
      _startAnimationSequence();
    }
  }

  Future<void> _startAnimationSequence() async {
    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    _textController.forward();

    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    if (!_authCheckRequested) {
      _authCheckRequested = true;
      context.read<AuthBloc>().add(AuthCheckRequested());
    }

    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      _fadeOutController.forward();
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _fadeOutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final logoSize = (screenWidth * 0.7).clamp(0.0, 260.0);

    return AnimatedBuilder(
      animation: Listenable.merge([
        _logoController,
        _textController,
        _fadeOutController,
      ]),
      builder: (context, child) {
        return Opacity(
          opacity: _backdropOpacity.value,
          child: Transform.translate(
            offset: Offset(0, _backdropPosition.value),
            child: Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.translate(
                        offset: Offset(0, _logoPosition.value),
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: SizedBox(
                            width: logoSize,
                            height: logoSize,
                            child: _imageLoaded
                                ? Image.network(
                                    _imageUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.church,
                                        size: 100,
                                        color: Color(0xFFBD811F),
                                      );
                                    },
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Opacity(
                      opacity: _textOpacity.value,
                      child: Transform.translate(
                        offset: Offset(0, _textPosition.value),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'IGLESIA CRISTIANA MORANDO EN SIÓN',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              letterSpacing: 3.0,
                              color: Color(0xFFBD811F),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
