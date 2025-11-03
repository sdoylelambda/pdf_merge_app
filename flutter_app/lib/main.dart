import 'dart:io' show File; // Only used in non-web platforms
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Web-only imports (ignored on mobile/desktop)
/// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void main() {
  runApp(const PDFMergeApp());
}

class PDFMergeApp extends StatelessWidget {
  const PDFMergeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Merger',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const PDFMergePage(),
    );
  }
}

class PDFMergePage extends StatefulWidget {
  const PDFMergePage({super.key});

  @override
  State<PDFMergePage> createState() => _PDFMergePageState();
}

class _PDFMergePageState extends State<PDFMergePage> {
  List<PlatformFile> selectedFiles = [];
  bool isMerging = false;
  final String apiUrl = "http://127.0.0.1:5000/merge_pdfs"; // Local backend

  Future<void> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      setState(() => selectedFiles = result.files);
    }
  }

  Future<void> mergeFiles() async {
    if (selectedFiles.isEmpty) return;

    setState(() => isMerging = true);

    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

      for (var file in selectedFiles) {
        if (kIsWeb) {
          // For web, use bytes (no file path available)
          request.files.add(
            http.MultipartFile.fromBytes(
              'files',
              file.bytes!,
              filename: file.name,
            ),
          );
        } else {
          // For mobile/desktop, use file path
          request.files.add(
            await http.MultipartFile.fromPath('files', file.path!),
          );
        }
      }

      var response = await request.send();

      if (response.statusCode == 200) {
        final bytes = await response.stream.toBytes();

        if (kIsWeb) {
          // --- WEB DOWNLOAD ---
          final blob = html.Blob([bytes]);
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: url)
            ..setAttribute("download", "merged.pdf")
            ..click();
          html.Url.revokeObjectUrl(url);
        } else {
          // --- DESKTOP / MOBILE SAVE ---
          final dir = await getApplicationDocumentsDirectory();
          final output = File('${dir.path}/merged.pdf');
          await output.writeAsBytes(bytes);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Merged PDF saved to: ${output.path}')),
            );
          }
        }
      } else {
        _showSnack('Merge failed: ${response.statusCode}');
      }
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      setState(() => isMerging = false);
    }
  }

  void _showSnack(String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("PDF Merger")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text("Select PDFs"),
              onPressed: pickFiles,
            ),
            const SizedBox(height: 16),
            if (selectedFiles.isNotEmpty)
              Expanded(
                child: ListView(
                  children: selectedFiles
                      .map(
                        (f) => ListTile(
                          title: Text(f.name),
                          leading: const Icon(Icons.picture_as_pdf),
                        ),
                      )
                      .toList(),
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: isMerging
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.merge_type),
              label: Text(isMerging ? "Merging..." : "Merge PDFs"),
              onPressed: isMerging ? null : mergeFiles,
            ),
          ],
        ),
      ),
    );
  }
}
