import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ms_app/features/auth/bloc/auth_bloc.dart';
import 'package:ms_app/features/auth/bloc/auth_event.dart';
import 'package:ms_app/features/marketing/events/event_bloc.dart';
import 'package:ms_app/features/marketing/events/event_repository.dart';
import 'package:ms_app/features/marketing/events/screens/event_list_screen.dart';

import '../../../core/api/api_client.dart';

class MarketingHomeScreen extends StatelessWidget {
  final ApiClient apiClient;
  const MarketingHomeScreen({super.key, required this.apiClient});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.event),
            title: const Text('Gestión de eventos'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) =>
                        EventBloc(EventRepository(apiClient: apiClient))
                          ..add(LoadAllEvents()),
                    child: EventListScreen(),
                  ),
                ),
              );
            },
          ),
          // Aquí puedes agregar más submódulos como anuncios
        ],
      ),
    );
  }
}
