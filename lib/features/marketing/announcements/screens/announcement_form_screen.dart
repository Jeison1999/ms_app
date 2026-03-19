import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ms_app/core/services/cloudinary_service.dart';
import 'package:ms_app/Core/widgets/app_section_app_bar.dart';
import '../announcement_bloc.dart';
import '../announcement_repository.dart';
import '../models/announcement_model.dart';
import '../widgets/announcement_form_widgets.dart';

class AnnouncementFormScreen extends StatelessWidget {
  final AnnouncementRepository repository;
  final AnnouncementModel? initialAnnouncement;

  const AnnouncementFormScreen({
    super.key,
    required this.repository,
    this.initialAnnouncement,
  });

  bool get _isEdit => initialAnnouncement != null;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AnnouncementBloc(repository),
      child: _AnnouncementFormView(
        initialAnnouncement: initialAnnouncement,
        isEdit: _isEdit,
      ),
    );
  }
}

class _AnnouncementFormView extends StatefulWidget {
  final AnnouncementModel? initialAnnouncement;
  final bool isEdit;

  const _AnnouncementFormView({
    required this.initialAnnouncement,
    required this.isEdit,
  });

  @override
  State<_AnnouncementFormView> createState() => _AnnouncementFormViewState();
}

class _AnnouncementFormViewState extends State<_AnnouncementFormView> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _mediaUrlController;
  late String _mediaType;
  late String _aspectRatio;
  late DateTime? _publishedAt;
  bool _isUploadingImage = false;

  static const List<String> mediaTypes = ['image', 'video'];
  static const List<String> aspectRatios = ['16:9', '1:1', '4:3', '9:16'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.initialAnnouncement?.title ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.initialAnnouncement?.description ?? '',
    );
    _mediaUrlController = TextEditingController(
      text: widget.initialAnnouncement?.mediaUrl ?? '',
    );
    _mediaType = widget.initialAnnouncement?.mediaType ?? 'image';
    _aspectRatio = widget.initialAnnouncement?.aspectRatio ?? '16:9';
    _publishedAt = widget.initialAnnouncement?.publishedAt;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _mediaUrlController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final data = <String, dynamic>{
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'media_url': _mediaUrlController.text.trim().isEmpty
          ? null
          : _mediaUrlController.text.trim(),
      'media_type': _mediaType,
      'aspect_ratio': _aspectRatio,
    };

    // Solo incluir published_at si tiene valor (mantener fecha existente en edición)
    if (_publishedAt != null) {
      data['published_at'] = _publishedAt!.toUtc().toIso8601String();
    }

    if (widget.isEdit) {
      context.read<AnnouncementBloc>().add(
        UpdateAnnouncement(widget.initialAnnouncement!.id, data),
      );
    } else {
      context.read<AnnouncementBloc>().add(CreateAnnouncement(data));
    }
  }

  void _clearImage() {
    setState(() {
      _mediaUrlController.clear();
    });
  }

  Future<void> _pickAndUploadImage() async {
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
      _mediaUrlController.text = url;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imagen subida correctamente')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al subir imagen: $e')));
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AnnouncementBloc, AnnouncementState>(
      listener: (context, state) {
        if (state is AnnouncementSuccess) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
          Navigator.of(context).pop(true);
        } else if (state is AnnouncementError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        final isLoading = state is AnnouncementLoading || _isUploadingImage;
        final mediaUrl = _mediaUrlController.text.trim();
        return Scaffold(
          appBar: DefaultSectionAppBar(
            titleText: widget.isEdit ? 'Editar anuncio' : 'Nuevo anuncio',
          ),
          bottomNavigationBar: AnnouncementActionBar(
            secondary: AnnouncementCancelButton(
              isLoading: isLoading,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            primary: AnnouncementSubmitButton(
              isEdit: widget.isEdit,
              isLoading: isLoading,
              onPressed: _submit,
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
                  Theme.of(context).colorScheme.surface,
                ],
              ),
            ),
            child: SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    AnnouncementFormHeader(isEdit: widget.isEdit),
                    const SizedBox(height: 14),
                    AnnouncementFormSection(
                      title: 'Información principal',
                      icon: Icons.edit_note_rounded,
                      subtitle: 'Datos básicos del anuncio.',
                      children: [
                        AnnouncementInputField(
                          controller: _titleController,
                          label: 'Título',
                          icon: Icons.title_rounded,
                          hint: 'Ej. Promoción especial',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'El título es obligatorio';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        AnnouncementInputField(
                          controller: _descriptionController,
                          label: 'Descripción',
                          icon: Icons.description_rounded,
                          hint: 'Describe el contenido del anuncio',
                          minLines: 3,
                          maxLines: 5,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'La descripción es obligatoria';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    AnnouncementFormSection(
                      title: 'Media',
                      icon: Icons.image_rounded,
                      subtitle: 'Puedes pegar una URL o subir desde galería.',
                      children: [
                        AnnouncementInputField(
                          controller: _mediaUrlController,
                          label: 'URL de media (opcional)',
                          icon: Icons.link_rounded,
                          hint: 'https://...',
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 10),
                        AnnouncementImageTools(
                          hasImage: mediaUrl.isNotEmpty,
                          isUploading: _isUploadingImage,
                          isDisabled: isLoading,
                          onUpload: _pickAndUploadImage,
                          onClear: _clearImage,
                        ),
                        const SizedBox(height: 10),
                        if (mediaUrl.isNotEmpty) ...[
                          AnnouncementImagePreview(mediaUrl: mediaUrl),
                        ] else ...[
                          const AnnouncementImagePlaceholder(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),
                    AnnouncementFormSection(
                      title: 'Configuración',
                      icon: Icons.settings_rounded,
                      subtitle: 'Tipo de media y proporciones.',
                      children: [
                        _buildMediaTypeDropdown(),
                        const SizedBox(height: 12),
                        _buildAspectRatioDropdown(),
                      ],
                    ),
                    const SizedBox(height: 110),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMediaTypeDropdown() {
    final colorScheme = Theme.of(context).colorScheme;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: colorScheme.outlineVariant),
    );
    return DropdownButtonFormField<String>(
      value: _mediaType,
      decoration: InputDecoration(
        labelText: 'Tipo de media',
        prefixIcon: const Icon(Icons.image_rounded),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        filled: true,
        fillColor: colorScheme.surface.withValues(alpha: 0.92),
      ),
      items: mediaTypes.map((type) {
        return DropdownMenuItem(
          value: type,
          child: Text(type == 'image' ? 'Imagen' : 'Video'),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _mediaType = value);
        }
      },
    );
  }

  Widget _buildAspectRatioDropdown() {
    final colorScheme = Theme.of(context).colorScheme;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: colorScheme.outlineVariant),
    );
    return DropdownButtonFormField<String>(
      value: _aspectRatio,
      decoration: InputDecoration(
        labelText: 'Relación de aspecto',
        prefixIcon: const Icon(Icons.aspect_ratio_rounded),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        filled: true,
        fillColor: colorScheme.surface.withValues(alpha: 0.92),
      ),
      items: aspectRatios.map((ratio) {
        return DropdownMenuItem(value: ratio, child: Text(ratio));
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _aspectRatio = value);
        }
      },
    );
  }
}
