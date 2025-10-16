import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

Future<String?> downloadPdf(BuildContext context, String url, String filename) async {
  try {
    // ======== 🔹 CEK & MINTA IZIN SESUAI VERSI ANDROID ========
    bool hasPermission = false;

    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted) {
        hasPermission = true;
      } else {
        final status = await Permission.manageExternalStorage.request();
        hasPermission = status.isGranted;
      }
    } else {
      // iOS tidak perlu izin khusus
      hasPermission = true;
    }

    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Izin penyimpanan ditolak. Buka pengaturan aplikasi dan aktifkan izin penyimpanan.')),
      );
      return null;
    }

    // ======== 🔹 PILIH LOKASI PENYIMPANAN SESUAI SISTEM ========
    Directory? saveDir;
    if (Platform.isAndroid) {
      saveDir = Directory("/storage/emulated/0/Download");
      if (!await saveDir.exists()) {
        saveDir = await getExternalStorageDirectory();
      }
    } else {
      saveDir = await getApplicationDocumentsDirectory();
    }

    final filePath = "${saveDir!.path}/$filename";
    final file = File(filePath);

    // ======== 🔹 DOWNLOAD FILE ========
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('⬇️ Mengunduh $filename...')),
    );

    await Dio().download(url, filePath, onReceiveProgress: (count, total) {
      if (total > 0) {
        final progress = (count / total * 100).toStringAsFixed(0);
        debugPrint("Download progress: $progress%");
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ Unduhan selesai: $filename')),
    );

    return filePath;
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('❌ Gagal mengunduh: $e')),
    );
    return null;
  }
}

Future<void> openPdfFile(String path) async {
  await OpenFilex.open(path);
}
