import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/animated_logo_header.dart';
import '../widgets/login_form_content.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;
  String? _loginErrorMessage;

  // Animation controllers
  late AnimationController _logoAnimationController;
  late AnimationController _contentAnimationController;

  // Logo animations
  late Animation<double> _logoOpacity;
  late Animation<double> _logoScale;
  late Animation<double> _logoContainerSlide;

  // Content animations
  late Animation<double> _titleOpacity;
  late Animation<double> _titleSlide;
  late Animation<double> _formOpacity;
  late Animation<double> _formSlide;
  late Animation<double> _formContainerSlide;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    // Logo animation controller (800ms)
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Content animation controller (1000ms)
    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Logo animations
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _logoScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _logoAnimationController, curve: Curves.easeOut),
    );

    _logoContainerSlide = Tween<double>(begin: -50.0, end: 0.0).animate(
      CurvedAnimation(parent: _logoAnimationController, curve: Curves.easeOut),
    );

    // Title animations
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    _titleSlide = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _contentAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Form animations
    _formOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentAnimationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
      ),
    );

    _formSlide = Tween<double>(begin: 25.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _contentAnimationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _formContainerSlide = Tween<double>(begin: 60.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _contentAnimationController,
        curve: Curves.easeOut,
      ),
    );
  }

  void _startAnimations() async {
    _logoAnimationController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      _contentAnimationController.forward();
    }
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        AuthLoginRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _contentAnimationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFC48A2C);

    return Scaffold(
      backgroundColor: primaryColor,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            setState(() {
              _loginErrorMessage = state.message;
            });
          } else if (state is AuthLoading) {
            setState(() {
              _loginErrorMessage = null;
            });
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [primaryColor, Color(0xFFEAC389)],
                ),
              ),
              child: Column(
                children: [
                  // Header animado con logo
                  AnimatedBuilder(
                    animation: _logoAnimationController,
                    builder: (context, child) {
                      return AnimatedLogoHeader(
                        opacity: _logoOpacity,
                        scale: _logoScale,
                        slideOffset: _logoContainerSlide,
                        imageUrl:
                            'https://res.cloudinary.com/dsm6diilz/image/upload/v1771519476/logoms_prnuap.png',
                      );
                    },
                  ),
                  // Contenedor del formulario animado
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _contentAnimationController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _formContainerSlide.value),
                          child: Container(
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(32),
                                topRight: Radius.circular(32),
                              ),
                            ),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 32,
                              ),
                              child: LoginFormContent(
                                formKey: _formKey,
                                emailController: _emailController,
                                passwordController: _passwordController,
                                obscurePassword: _obscurePassword,
                                rememberMe: _rememberMe,
                                isLoading: isLoading,
                                onTogglePassword: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                onRememberMeChanged: (value) {
                                  setState(() {
                                    _rememberMe = value;
                                  });
                                },
                                onLogin: _handleLogin,
                                errorMessage: _loginErrorMessage,
                                titleOpacity: _titleOpacity,
                                titleSlide: _titleSlide,
                                formOpacity: _formOpacity,
                                formSlide: _formSlide,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
