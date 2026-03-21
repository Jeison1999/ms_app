import 'package:flutter/material.dart';

class AnnouncementFormHeader extends StatelessWidget {
  final bool isEdit;

  const AnnouncementFormHeader({super.key, required this.isEdit});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withValues(alpha: 0.2),
            colorScheme.primary.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary.withValues(alpha: 0.18),
            ),
            child: Icon(Icons.campaign_rounded, color: colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Actualizar anuncio' : 'Crear nuevo anuncio',
                  style: TextStyle(
                    fontSize: 18.5,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Completa la información principal, configura el media y estado.',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AnnouncementFormSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final String? subtitle;

  const AnnouncementFormSection({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.68),
                fontWeight: FontWeight.w500,
                fontSize: 12.8,
              ),
            ),
          ],
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class AnnouncementInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  final int minLines;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final String? hint;

  const AnnouncementInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.minLines = 1,
    this.maxLines = 1,
    this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: colorScheme.outlineVariant),
    );
    return TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: colorScheme.surface.withValues(alpha: 0.92),
        border: baseBorder,
        enabledBorder: baseBorder,
        focusedBorder: baseBorder.copyWith(
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
      validator: validator,
    );
  }
}

class AnnouncementImagePreview extends StatelessWidget {
  final String mediaUrl;
  final String mediaType;

  const AnnouncementImagePreview({
    super.key,
    required this.mediaUrl,
    required this.mediaType,
  });

  @override
  Widget build(BuildContext context) {
    if (mediaUrl.isEmpty) return const SizedBox.shrink();
    if (mediaType == 'video') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        ),
        child: const Row(
          children: [
            Icon(Icons.videocam_rounded),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Video cargado. La vista previa de video no esta habilitada aqui.',
              ),
            ),
          ],
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Image.network(
              mediaUrl,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                height: 84,
                alignment: Alignment.center,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Text('No se pudo cargar la imagen'),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.black.withValues(alpha: 0.56),
                ),
                child: const Text(
                  'Vista previa',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.34),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnnouncementImagePlaceholder extends StatelessWidget {
  const AnnouncementImagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      height: 130,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
            size: 28,
          ),
          const SizedBox(height: 6),
          Text(
            'Agrega una URL o sube una imagen/video',
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.75),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class AnnouncementCancelButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const AnnouncementCancelButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        onPressed: isLoading ? null : onPressed,
        icon: const Icon(Icons.close_rounded),
        label: const Text('Cancelar'),
      ),
    );
  }
}

class AnnouncementActionBar extends StatelessWidget {
  final Widget primary;
  final Widget secondary;

  const AnnouncementActionBar({
    super.key,
    required this.primary,
    required this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: secondary),
          const SizedBox(width: 10),
          Expanded(child: primary),
        ],
      ),
    );
  }
}

class AnnouncementUploadImageButton extends StatelessWidget {
  final bool isUploading;
  final bool isDisabled;
  final VoidCallback onPressed;
  final String mediaType;

  const AnnouncementUploadImageButton({
    super.key,
    required this.isUploading,
    required this.isDisabled,
    required this.onPressed,
    required this.mediaType,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: isDisabled ? null : onPressed,
      icon: isUploading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              mediaType == 'video'
                  ? Icons.video_call_rounded
                  : Icons.cloud_upload_rounded,
            ),
      label: Text(
        isUploading
            ? (mediaType == 'video'
                  ? 'Subiendo video...'
                  : 'Subiendo imagen...')
            : (mediaType == 'video'
                  ? 'Subir video a Cloudinary'
                  : 'Subir imagen a Cloudinary'),
      ),
    );
  }
}

class AnnouncementSubmitButton extends StatelessWidget {
  final bool isEdit;
  final bool isLoading;
  final VoidCallback onPressed;

  const AnnouncementSubmitButton({
    super.key,
    required this.isEdit,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save_rounded),
        label: Text(isEdit ? 'Actualizar anuncio' : 'Crear anuncio'),
      ),
    );
  }
}

class AnnouncementImageTools extends StatelessWidget {
  final bool hasImage;
  final bool isUploading;
  final bool isDisabled;
  final String mediaType;
  final VoidCallback onUpload;
  final VoidCallback onClear;

  const AnnouncementImageTools({
    super.key,
    required this.hasImage,
    required this.isUploading,
    required this.isDisabled,
    required this.mediaType,
    required this.onUpload,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AnnouncementUploadImageButton(
            isUploading: isUploading,
            isDisabled: isDisabled || isUploading,
            mediaType: mediaType,
            onPressed: onUpload,
          ),
        ),
        if (hasImage) ...[
          const SizedBox(width: 8),
          SizedBox(
            width: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: isDisabled ? null : onClear,
              child: const Icon(Icons.delete_outline_rounded),
            ),
          ),
        ],
      ],
    );
  }
}
