import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Escribe el Excel en el cache de la app (path_provider) y abre el sheet
/// del sistema para guardar/compartir — el usuario elige el destino.
class PersonExcelExporter {
  PersonExcelExporter._();

  static const mimeType =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

  static String _safeFilename(String filename) {
    var name = filename.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    if (name.isEmpty) name = 'personas_export.xlsx';
    if (!name.toLowerCase().endsWith('.xlsx')) {
      name = '$name.xlsx';
    }
    return name;
  }

  static Future<Directory> _cacheDir() async {
    try {
      return await getTemporaryDirectory();
    } catch (_) {
      return await getApplicationCacheDirectory();
    }
  }

  static Future<File> writeCacheFile({
    required Uint8List bytes,
    required String filename,
  }) async {
    final safeName = _safeFilename(filename);
    final dir = await _cacheDir();
    final file = File('${dir.path}/$safeName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static Future<ShareResult> shareExcel({
    required Uint8List bytes,
    required String filename,
  }) async {
    final safeName = _safeFilename(filename);

    // 1) Intentar compartir desde memoria (el plugin usa su propio cache).
    try {
      return await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              mimeType: mimeType,
              name: safeName,
            ),
          ],
          subject: 'Exportación de personas',
          text: 'Informe de personas ($safeName)',
        ),
      );
    } catch (_) {
      // 2) Fallback: archivo real en cache de la app + share por path.
      final file = await writeCacheFile(bytes: bytes, filename: safeName);
      return SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              file.path,
              mimeType: mimeType,
              name: safeName,
            ),
          ],
          subject: 'Exportación de personas',
          text: 'Informe de personas ($safeName)',
        ),
      );
    }
  }
}
