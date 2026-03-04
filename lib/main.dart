import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/api/api_client.dart';
import 'core/utils/storage_service.dart';
import 'Core/theme/app_theme.dart';
import 'features/auth/repository/auth_repository.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_state.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'routes/role_based_router.dart';

void main() {
  runApp(const MsApp());
}

class MsApp extends StatelessWidget {
  const MsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final storageService = StorageService();
    final apiClient = ApiClient(getToken: () => storageService.getToken());
    final authRepository = AuthRepository(
      apiClient: apiClient,
      storageService: storageService,
    );

    return BlocProvider(
      create: (context) => AuthBloc(authRepository: authRepository),
      child: MaterialApp(
        title: 'MS App',
        theme: AppTheme.lightTheme,
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthInitial || state is AuthChecking) {
              return const SplashScreen();
            } else if (state is AuthAuthenticated) {
              return RoleBasedRouter.getHomeScreen(
                state.user,
                apiClient: apiClient,
              );
            } else {
              return const LoginScreen();
            }
          },
        ),
      ),
    );
  }
}
