import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class PdfPreviewPage extends StatelessWidget {
  final String filePath;
  final String title;

  const PdfPreviewPage({super.key, required this.filePath, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: PDFView(
        filePath: filePath,
      ),
    );
  }
}
