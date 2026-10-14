import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class UserProfilePhotoStore {
  UserProfilePhotoStore({
    Future<Directory> Function()? documentsDirectoryProvider,
  }) : _documentsDirectoryProvider =
           documentsDirectoryProvider ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _documentsDirectoryProvider;

  Future<String> savePickedImage({
    required String email,
    required String sourcePath,
  }) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw FileSystemException(
        'File foto yang dipilih tidak ditemukan.',
        sourcePath,
      );
    }

    final documentsDirectory = await _documentsDirectoryProvider();
    final normalizedEmail = email.trim().toLowerCase();
    final accountKey = base64Url.encode(utf8.encode(normalizedEmail));
    final photoDirectory = Directory(
      '${documentsDirectory.path}${Platform.pathSeparator}profile_photos',
    );
    await photoDirectory.create(recursive: true);

    final sourceName = source.uri.pathSegments.last;
    final extensionIndex = sourceName.lastIndexOf('.');
    final extension = extensionIndex >= 0
        ? sourceName.substring(extensionIndex).toLowerCase()
        : '.jpg';
    final imageVersion = DateTime.now().microsecondsSinceEpoch;
    final destination = File(
      '${photoDirectory.path}${Platform.pathSeparator}'
      'profile_${accountKey}_$imageVersion$extension',
    );
    await source.copy(destination.path);

    return destination.path;
  }
}
