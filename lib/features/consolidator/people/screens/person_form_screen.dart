import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ms_app/core/services/cloudinary_service.dart';
import 'package:ms_app/Core/widgets/app_section_app_bar.dart';
import '../models/person_model.dart';
import '../person_bloc.dart';
import '../person_repository.dart';

class PersonFormScreen extends StatelessWidget {
  final PersonRepository repository;
  final PersonModel? initialPerson;

  const PersonFormScreen({
    super.key,
    required this.repository,
    this.initialPerson,
  });

  bool get _isEdit => initialPerson != null;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PersonBloc(repository),
      child: _PersonFormView(
        initialPerson: initialPerson,
        isEdit: _isEdit,
      ),
    );
  }
}

class _PersonFormView extends StatefulWidget {
  final PersonModel? initialPerson;
  final bool isEdit;

  const _PersonFormView({
    required this.initialPerson,
    required this.isEdit,
  });

  @override
  State<_PersonFormView> createState() => _PersonFormViewState();
}

class _PersonFormViewState extends State<_PersonFormView> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _documentNumberController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _photoUrlController;

  String? _documentType;
  String? _sex;
  DateTime? _birthDate;
  bool _isUploadingImage = false;

  static const documentTypes = ['CC', 'TI', 'CE', 'PA', 'NIT', 'OTRO'];
  static const sexOptions = <String, String>{
    'male': 'Masculino',
    'female': 'Femenino',
    'other': 'Otro',
    'unspecified': 'No especificado',
  };

  @override
  void initState() {
    super.initState();
    final p = widget.initialPerson;
    _firstNameController = TextEditingController(text: p?.firstName ?? '');
    _lastNameController = TextEditingController(text: p?.lastName ?? '');
    _documentNumberController =
        TextEditingController(text: p?.documentNumber ?? '');
    _phoneController = TextEditingController(text: p?.phone ?? '');
    _emailController = TextEditingController(text: p?.email ?? '');
    _addressController = TextEditingController(text: p?.address ?? '');
    _cityController = TextEditingController(text: p?.city ?? '');
    _photoUrlController = TextEditingController(text: p?.photoUrl ?? '');
    _documentType = p?.documentType;
    _sex = p?.sex;
    _birthDate = p?.birthDate;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _documentNumberController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  String? _formatBirthDate(DateTime? date) {
    if (date == null) return null;
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 18),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() => _isUploadingImage = true);
    try {
      final url = await _cloudinaryService.uploadImage(
        filePath: picked.path,
        fileName: picked.name,
      );
      _photoUrlController.text = url;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto subida correctamente')),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir foto: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final data = <String, dynamic>{
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'document_type': _documentType,
      'document_number': _documentNumberController.text.trim().isEmpty
          ? null
          : _documentNumberController.text.trim(),
      'birth_date': _formatBirthDate(_birthDate),
      'sex': _sex,
      'phone': _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      'email': _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      'address': _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      'city': _cityController.text.trim().isEmpty
          ? null
          : _cityController.text.trim(),
      'photo_url': _photoUrlController.text.trim().isEmpty
          ? null
          : _photoUrlController.text.trim(),
    };

    if (widget.isEdit) {
      context.read<PersonBloc>().add(
        UpdatePerson(widget.initialPerson!.id, data),
      );
    } else {
      context.read<PersonBloc>().add(CreatePerson(data));
    }
  }

  InputDecoration _decoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final photoUrl = _photoUrlController.text.trim();

    return BlocConsumer<PersonBloc, PersonState>(
      listener: (context, state) {
        if (state is PersonSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          Navigator.of(context).pop(true);
        } else if (state is PersonError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        final loading = state is PersonLoading;
        return Scaffold(
          appBar: DefaultSectionAppBar(
            titleText: widget.isEdit ? 'Editar persona' : 'Nueva persona',
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 52,
                        backgroundColor:
                            colorScheme.primary.withValues(alpha: 0.14),
                        backgroundImage: photoUrl.isNotEmpty
                            ? NetworkImage(photoUrl)
                            : null,
                        child: photoUrl.isEmpty
                            ? Icon(
                                Icons.person,
                                size: 48,
                                color: colorScheme.primary,
                              )
                            : null,
                      ),
                      if (_isUploadingImage)
                        const Positioned.fill(
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: loading || _isUploadingImage
                          ? null
                          : _pickAndUploadPhoto,
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Subir foto'),
                    ),
                    if (photoUrl.isNotEmpty)
                      TextButton(
                        onPressed: loading
                            ? null
                            : () {
                                _photoUrlController.clear();
                                setState(() {});
                              },
                        child: const Text('Quitar'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _firstNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _decoration('Nombres *', icon: Icons.badge_outlined),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lastNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration:
                      _decoration('Apellidos *', icon: Icons.badge_outlined),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _documentType,
                  decoration: _decoration('Tipo de documento'),
                  items: documentTypes
                      .map(
                        (t) => DropdownMenuItem(value: t, child: Text(t)),
                      )
                      .toList(),
                  onChanged: loading
                      ? null
                      : (v) => setState(() => _documentType = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _documentNumberController,
                  keyboardType: TextInputType.number,
                  decoration: _decoration('Número de documento'),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: loading ? null : _pickBirthDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: _decoration(
                      'Fecha de nacimiento',
                      icon: Icons.cake_outlined,
                    ),
                    child: Text(
                      _birthDate == null
                          ? 'Seleccionar'
                          : _formatBirthDate(_birthDate)!,
                      style: TextStyle(
                        color: _birthDate == null
                            ? Colors.black45
                            : Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _sex,
                  decoration: _decoration('Sexo'),
                  items: sexOptions.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      )
                      .toList(),
                  onChanged:
                      loading ? null : (v) => setState(() => _sex = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _decoration('Teléfono', icon: Icons.phone),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _decoration('Email', icon: Icons.email_outlined),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration:
                      _decoration('Dirección', icon: Icons.home_outlined),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cityController,
                  textCapitalization: TextCapitalization.words,
                  decoration:
                      _decoration('Ciudad', icon: Icons.location_city_outlined),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: loading || _isUploadingImage ? null : _submit,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            widget.isEdit ? 'Guardar cambios' : 'Crear persona',
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
