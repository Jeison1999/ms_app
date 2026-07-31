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
  static const Duration _publishSkewBuffer = Duration(minutes: 2);

  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _mediaUrlController;
  late String _mediaType;
  late String _aspectRatio;
  late bool _publishNow;
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
    // En edición: toggle basado si published_at existe. En creación: on por defecto
    if (widget.isEdit) {
      _publishNow = widget.initialAnnouncement?.publishedAt != null;
    } else {
      _publishNow = true;
      _publishedAt = DateTime.now().add(_publishSkewBuffer);
    }
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

    // Envío simple: si toggle está on, envía published_at; si está off, envía null
    final publishedAtToSend = _publishNow ? _publishedAt : null;

    final data = <String, dynamic>{
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'media_url': _mediaUrlController.text.trim().isEmpty
          ? null
          : _mediaUrlController.text.trim(),
      'media_type': _mediaType,
      'aspect_ratio': _aspectRatio,
      'published_at': publishedAtToSend?.toUtc().toIso8601String(),
    };

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

  Future<void> _pickAndUploadMedia() async {
    final bool isVideo = _mediaType == 'video';
    final XFile? picked = isVideo
        ? await _imagePicker.pickVideo(source: ImageSource.gallery)
        : await _imagePicker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 100,
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
        SnackBar(
          content: Text(
            isVideo
                ? 'Video subido correctamente'
                : 'Imagen subida correctamente',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isVideo ? 'Error al subir video: $e' : 'Error al subir imagen: $e',
          ),
        ),
      );
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
                            if (value.trim().length < 3) {
                              return 'El título debe tener al menos 3 caracteres';
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
                      subtitle:
                          'Puedes pegar una URL o subir imagen/video desde galería.',
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
                          mediaType: _mediaType,
                          onUpload: _pickAndUploadMedia,
                          onClear: _clearImage,
                        ),
                        const SizedBox(height: 10),
                        if (mediaUrl.isNotEmpty) ...[
                          AnnouncementImagePreview(
                            mediaUrl: mediaUrl,
                            mediaType: _mediaType,
                          ),
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
                    const SizedBox(height: 14),
                    AnnouncementFormSection(
                      title: 'Publicación',
                      icon: Icons.publish_rounded,
                      subtitle:
                          'Actívalo para publicar el anuncio inmediatamente.',
                      children: [_buildPublishToggle()],
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
      initialValue: _mediaType,
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
      initialValue: _aspectRatio,
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

  Widget _buildPublishToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Publicar ahora',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                _publishNow
                    ? 'Este anuncio quedara visible para los usuarios.'
                    : 'Se guardara como no publicado.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.black54),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Switch(
          value: _publishNow,
          onChanged: (value) {
            setState(() {
              _publishNow = value;
              if (value) {
                // Al activar: establece fecha futura
                _publishedAt = DateTime.now().add(_publishSkewBuffer);
              } else {
                // Al desactivar: limpia la fecha
                _publishedAt = null;
              }
            });
          },
        ),
      ],
    );
  }
}
