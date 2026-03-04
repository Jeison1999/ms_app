import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ms_app/core/services/cloudinary_service.dart';
import 'package:ms_app/Core/widgets/app_section_app_bar.dart';
import '../event_bloc.dart';
import '../event_repository.dart';
import '../models/event_model.dart';

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
      child: _EventFormView(
        initialEvent: initialEvent,
        isEdit: _isEdit,
      ),
    );
  }
}

class _EventFormView extends StatefulWidget {
  final EventModel? initialEvent;
  final bool isEdit;

  const _EventFormView({
    required this.initialEvent,
    required this.isEdit,
  });

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
    _titleController = TextEditingController(text: widget.initialEvent?.title ?? '');
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir imagen: $e')),
      );
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          Navigator.of(context).pop(true);
        } else if (state is EventError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is EventLoading || _isUploadingImage;
        final imageUrl = _imageUrlController.text.trim();
        return Scaffold(
          appBar: DefaultSectionAppBar(
            titleText: widget.isEdit ? 'Editar evento' : 'Nuevo evento',
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El título es obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'La descripción es obligatoria';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Ubicación',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'La ubicación es obligatoria';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _imageUrlController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'URL de imagen (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: isLoading ? null : _pickAndUploadImage,
                  icon: _isUploadingImage
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload),
                  label: Text(
                    _isUploadingImage
                        ? 'Subiendo imagen...'
                        : 'Subir imagen a Cloudinary',
                  ),
                ),
                if (imageUrl.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        height: 80,
                        alignment: Alignment.center,
                        color: Colors.grey.shade200,
                        child: const Text('No se pudo cargar la imagen'),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                InkWell(
                  onTap: isLoading ? null : _pickDateTime,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha y hora',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(_formatDate(_eventDate)),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: isLoading ? null : _submit,
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(widget.isEdit ? 'Actualizar' : 'Crear'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
