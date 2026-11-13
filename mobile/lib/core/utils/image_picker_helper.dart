import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class PickedImageData {
  final File file;
  final int originalBytes;
  final int compressedBytes;

  PickedImageData({
    required this.file,
    required this.originalBytes,
    required this.compressedBytes,
  });

  String get compressedKb => '${(compressedBytes / 1024).toStringAsFixed(0)} KB';
  String get originalKb => '${(originalBytes / 1024).toStringAsFixed(0)} KB';
}

class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Shows a clean bottom sheet allowing user to choose Camera or Gallery
  static Future<ImageSource?> showSourceSelector(BuildContext context) async {
    return await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pilih Sumber Foto Bukti',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Kamu bisa foto langsung dengan kamera atau ambil foto yang tersimpan di HP.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    // Camera Button
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.pop(ctx, ImageSource.camera),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFC7D2FE)),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF6366F1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 28),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Ambil Foto',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF4338CA),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Kamera Langsung',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: const Color(0xFF6366F1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Gallery Button
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDF2F8),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFBCFE8)),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEC4899),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 28),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Pilih dari Galeri',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFBE185D),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Foto Tersimpan',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: const Color(0xFFEC4899),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Picks and automatically compresses image for lightweight upload
  static Future<PickedImageData?> pickAndCompressImage(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );

    if (picked == null) return null;

    final origFile = File(picked.path);
    final origBytes = await origFile.length();

    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/task_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final XFile? compressed = await FlutterImageCompress.compressAndGetFile(
        origFile.absolute.path,
        targetPath,
        quality: 72,
        minWidth: 1024,
        minHeight: 1024,
      );

      if (compressed != null) {
        final compFile = File(compressed.path);
        final compBytes = await compFile.length();
        return PickedImageData(
          file: compFile,
          originalBytes: origBytes,
          compressedBytes: compBytes,
        );
      }
    } catch (_) {
      // Fallback to original file if compression fails or unsupported
    }

    return PickedImageData(
      file: origFile,
      originalBytes: origBytes,
      compressedBytes: origBytes,
    );
  }
}
