import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

/// Full-screen in-app PDF viewer.
/// Downloads and displays PDF files without leaving the app.
class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String? pdfTitle;

  const PdfViewerScreen({super.key, required this.pdfUrl, this.pdfTitle});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? localPath;
  bool isLoading = true;
  String? errorMessage;
  int currentPage = 0;
  int totalPages = 0;

  @override
  void initState() {
    super.initState();
    _downloadAndLoadPdf();
  }

  Future<void> _downloadAndLoadPdf() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Download PDF to local storage
      final response = await http.get(Uri.parse(widget.pdfUrl));

      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/temp_course.pdf');
        await file.writeAsBytes(response.bodyBytes);

        if (mounted) {
          setState(() {
            localPath = file.path;
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage =
                'Impossible de télécharger le PDF (Code: ${response.statusCode})';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Erreur de téléchargement: $e';
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.pdfTitle ?? 'Document PDF',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (totalPages > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${currentPage + 1}/$totalPages',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.blue),
                  const SizedBox(height: 16),
                  Text(
                    'Téléchargement du PDF...',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            )
          : errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _downloadAndLoadPdf,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : localPath != null
          ? PDFView(
              filePath: localPath!,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageFling: true,
              pageSnap: true,
              onRender: (pages) {
                setState(() {
                  totalPages = pages ?? 0;
                });
              },
              onPageChanged: (page, total) {
                setState(() {
                  currentPage = page ?? 0;
                  totalPages = total ?? 0;
                });
              },
              onError: (error) {
                setState(() {
                  errorMessage = 'Erreur d\'affichage du PDF';
                });
              },
            )
          : const Center(child: Text('Aucun fichier à afficher')),
    );
  }
}
