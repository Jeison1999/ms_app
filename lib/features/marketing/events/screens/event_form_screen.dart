import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ms_app/core/services/cloudinary_service.dart';
import 'package:ms_app/Core/widgets/app_section_app_bar.dart';
import '../event_bloc.dart';
import '../event_repository.dart';
import '../models/event_model.dart';
import '../widgets/event_form_widgets.dart';

class EventFormScreen extends StatelessWidget {
  final EventRepository repository;
  final EventModel? initialEvent;

  const EventFormScreen({
    super.key,
    required this.repository,
    this.initialEvent,
  });

  bool get _isEdit => initialEvent != null;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EventBloc(repository),
      child: _EventFormView(initialEvent: initialEvent, isEdit: _isEdit),
    );
  }
}

class _EventFormView extends StatefulWidget {
  final EventModel? initialEvent;
  final bool isEdit;

  const _EventFormView({required this.initialEvent, required this.isEdit});

  @override
  State<_EventFormView> createState() => _EventFormViewState();
}

class _EventFormViewState extends State<_EventFormView> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _imageUrlController;
  late DateTime _eventDate;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.initialEvent?.title ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.initialEvent?.description ?? '',
    );
    _locationController = TextEditingController(
      text: widget.initialEvent?.location ?? '',
    );
    _imageUrlController = TextEditingController(
      text: widget.initialEvent?.imageUrl ?? '',
    );
    _eventDate = widget.initialEvent?.eventDate.toLocal() ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min';
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_eventDate),
    );
    if (pickedTime == null || !mounted) return;

    setState(() {
      _eventDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final data = <String, dynamic>{
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'event_date': _eventDate.toUtc().toIso8601String(),
      'location': _locationController.text.trim(),
      'image_url': _imageUrlController.text.trim().isEmpty
          ? null
          : _imageUrlController.text.trim(),
    };

    if (widget.isEdit) {
      context.read<EventBloc>().add(UpdateEvent(widget.initialEvent!.id, data));
    } else {
      context.read<EventBloc>().add(CreateEvent(data));
    }
  }

  void _clearImage() {
    setState(() {
      _imageUrlController.clear();
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
      _imageUrlController.text = url;
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
    return BlocConsumer<EventBloc, EventState>(
      listener: (context, state) {
        if (state is EventSuccess) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
          Navigator.of(context).pop(true);
        } else if (state is EventError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        final isLoading = state is EventLoading || _isUploadingImage;
        final imageUrl = _imageUrlController.text.trim();
        return Scaffold(
          appBar: DefaultSectionAppBar(
            titleText: widget.isEdit ? 'Editar evento' : 'Nuevo evento',
          ),
          bottomNavigationBar: EventActionBar(
            secondary: EventCancelButton(
              isLoading: isLoading,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            primary: EventSubmitButton(
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
                    EventFormHeader(isEdit: widget.isEdit),
                    const SizedBox(height: 14),
                    EventFormSection(
                      title: 'Informacion principal',
                      icon: Icons.edit_note_rounded,
                      subtitle:
                          'Datos basicos para identificar y describir el evento.',
                      children: [
                        EventInputField(
                          controller: _titleController,
                          label: 'Titulo',
                          icon: Icons.title_rounded,
                          hint: 'Ej. Feria de tecnologia 2026',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'El titulo es obligatorio';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        EventInputField(
                          controller: _descriptionController,
                          label: 'Descripcion',
                          icon: Icons.description_rounded,
                          hint: 'Resumen corto de que trata el evento',
                          minLines: 3,
                          maxLines: 5,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'La descripcion es obligatoria';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        EventInputField(
                          controller: _locationController,
                          label: 'Ubicacion',
                          icon: Icons.place_rounded,
                          hint: 'Ej. Centro de convenciones',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'La ubicacion es obligatoria';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    EventFormSection(
                      title: 'Imagen',
                      icon: Icons.image_rounded,
                      subtitle: 'Puedes pegar una URL o subirla desde galeria.',
                      children: [
                        EventInputField(
                          controller: _imageUrlController,
                          label: 'URL de imagen (opcional)',
                          icon: Icons.link_rounded,
                          hint: 'https://...',
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 10),
                        EventImageTools(
                          hasImage: imageUrl.isNotEmpty,
                          isUploading: _isUploadingImage,
                          isDisabled: isLoading,
                          onUpload: _pickAndUploadImage,
                          onClear: _clearImage,
                        ),
                        const SizedBox(height: 10),
                        if (imageUrl.isNotEmpty) ...[
                          EventImagePreview(imageUrl: imageUrl),
                        ] else ...[
                          const EventImagePlaceholder(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),
                    EventFormSection(
                      title: 'Agenda',
                      icon: Icons.event_rounded,
                      subtitle: 'Selecciona fecha y hora exacta del evento.',
                      children: [
                        EventDateTimeField(
                          value: _formatDate(_eventDate),
                          onTap: isLoading ? null : _pickDateTime,
                        ),
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
}
