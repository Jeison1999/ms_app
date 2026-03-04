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
  // URL optimizada con transformaciones de Cloudinary para carga rápida (formato auto, calidad auto, ancho 400)
  final String _imageUrl =
      'https://res.cloudinary.com/dsm6diilz/image/upload/f_auto,q_auto,w_400/v1771519478/logoms2_exyhn7.png';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _preloadImageAndStart();
  }

  void _initializeAnimations() {
    // Logo animation controller (1000ms) - más largo para ser más suave
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Text animation controller (400ms, starts at 600ms)
    _textController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Fade out animation controller (500ms, starts at 2500ms)
    _fadeOutController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Logo fade-in suave y gradual (como el texto)
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    // Movimiento suave desde arriba (más sutil)
    _logoPosition = Tween<double>(
      begin: -20.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOut));

    // Escala suave sin rebote
    _logoScale = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOut));

    // Text rise animation
    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    _textPosition = Tween<double>(
      begin: 10.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    // Backdrop fade out animation
    _backdropOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeOutController, curve: Curves.easeOut),
    );

    _backdropPosition = Tween<double>(begin: 0.0, end: -6.0).animate(
      CurvedAnimation(parent: _fadeOutController, curve: Curves.easeOut),
    );
  }

  Future<void> _preloadImageAndStart() async {
    // Precargar la imagen antes de mostrar animaciones
    try {
      await precacheImage(NetworkImage(_imageUrl), context);
    } catch (e) {
      // Ignorar error de precarga
    }

    if (mounted) {
      setState(() {
        _imageLoaded = true;
      });
      // Pequeña pausa para asegurar que el widget se actualice
      await Future.delayed(const Duration(milliseconds: 50));
      if (mounted) {
        _startAnimationSequence();
      }
    }
  }

  void _startAnimationSequence() async {
    // Start logo animation immediately (1000ms)
    _logoController.forward();

    // Start text animation justo después de que termina el logo
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) {
      _textController.forward();
    }

    // Wait to show splash for at least 2500ms total
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      // Check authentication only after animations are visible
      context.read<AuthBloc>().add(AuthCheckRequested());
    }

    // Start fade out after showing content
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
                    // Logo with waterfall animation
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
                    // Text with rise animation
                    Opacity(
                      opacity: _textOpacity.value,
                      child: Transform.translate(
                        offset: Offset(0, _textPosition.value),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: const Text(
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
