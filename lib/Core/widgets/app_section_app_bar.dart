import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/auth_event.dart';

Future<bool> confirmLogout(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Cerrar sesión'),
      content: const Text('¿Seguro que quieres cerrar sesión?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Cerrar sesión'),
        ),
      ],
    ),
  );
  return result == true;
}

Future<void> performLogout(BuildContext context) async {
  final confirmed = await confirmLogout(context);
  if (!confirmed || !context.mounted) return;

  context.read<AuthBloc>().add(AuthLogoutRequested());
  // Quita pantallas apiladas (detalle, listados, etc.) para que se vea el login.
  Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
}

abstract class AppSectionAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const AppSectionAppBar({super.key});

  String get titleText;
  bool get showBackButton;
  bool get showLogoutButton;
  bool get centerTitle;
  Color? get backgroundColor;
  Color? get foregroundColor;
  TextStyle? get titleStyle;
  PreferredSizeWidget? get bottomWidget;
  ShapeBorder? get shapeBorder;
  Clip get appBarClipBehavior;

  @protected
  Widget? buildLeading(BuildContext context) => null;

  @protected
  List<Widget> buildCustomActions(BuildContext context) => const [];

  @protected
  Future<void> onLogout(BuildContext context) => performLogout(context);

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottomWidget?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      ...buildCustomActions(context),
      if (showLogoutButton)
        IconButton(
          tooltip: 'Cerrar sesión',
          icon: const Icon(Icons.logout),
          onPressed: () => onLogout(context),
        ),
    ];

    return AppBar(
      automaticallyImplyLeading: showBackButton,
      leading: buildLeading(context),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      title: Text(titleText, style: titleStyle),
      actions: actions.isEmpty ? null : actions,
      bottom: bottomWidget,
      shape: shapeBorder,
      clipBehavior: appBarClipBehavior,
    );
  }
}

class DefaultSectionAppBar extends AppSectionAppBar {
  @override
  final String titleText;
  @override
  final bool showBackButton;
  @override
  final bool showLogoutButton;
  @override
  final bool centerTitle;
  @override
  final Color? backgroundColor;
  @override
  final Color? foregroundColor;
  @override
  final TextStyle? titleStyle;
  @override
  final PreferredSizeWidget? bottomWidget;
  @override
  final ShapeBorder? shapeBorder;
  @override
  final Clip appBarClipBehavior;
  final List<Widget> customActions;
  final VoidCallback? onBackPressed;
  final VoidCallback? onLogoutPressed;
  final bool roundedBottom;
  final double bottomRadius;

  const DefaultSectionAppBar({
    super.key,
    required this.titleText,
    this.showBackButton = true,
    this.showLogoutButton = true,
    this.centerTitle = true,
    this.backgroundColor,
    this.foregroundColor,
    this.titleStyle,
    this.bottomWidget,
    this.shapeBorder,
    this.appBarClipBehavior = Clip.antiAlias,
    this.customActions = const [],
    this.onBackPressed,
    this.onLogoutPressed,
    this.roundedBottom = true,
    this.bottomRadius = 22,
  });

  ShapeBorder? get _resolvedShape {
    if (shapeBorder != null) return shapeBorder;
    if (!roundedBottom) return null;
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        bottom: Radius.circular(bottomRadius),
      ),
    );
  }

  @override
  Widget? buildLeading(BuildContext context) {
    if (!showBackButton || onBackPressed == null) {
      return null;
    }

    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: onBackPressed,
    );
  }

  @override
  List<Widget> buildCustomActions(BuildContext context) => customActions;

  @override
  Future<void> onLogout(BuildContext context) async {
    final confirmed = await confirmLogout(context);
    if (!confirmed || !context.mounted) return;

    if (onLogoutPressed != null) {
      onLogoutPressed!.call();
    } else {
      context.read<AuthBloc>().add(AuthLogoutRequested());
    }

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      ...buildCustomActions(context),
      if (showLogoutButton)
        IconButton(
          tooltip: 'Cerrar sesión',
          icon: const Icon(Icons.logout),
          onPressed: () => onLogout(context),
        ),
    ];

    return AppBar(
      automaticallyImplyLeading: showBackButton,
      leading: buildLeading(context),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      title: Text(titleText, style: titleStyle),
      actions: actions.isEmpty ? null : actions,
      bottom: bottomWidget,
      shape: _resolvedShape,
      clipBehavior: appBarClipBehavior,
    );
  }
}
