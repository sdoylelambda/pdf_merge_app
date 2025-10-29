import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

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

    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
    for (var file in selectedFiles) {
      request.files.add(await http.MultipartFile.fromPath('files', file.path!));
    }

    var response = await request.send();

    if (response.statusCode == 200) {
      final bytes = await response.stream.toBytes();
      final dir = await getApplicationDocumentsDirectory();
      final output = File('${dir.path}/merged.pdf');
      await output.writeAsBytes(bytes);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Merged PDF saved to: ${output.path}')),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Merge failed: ${response.statusCode}')),
        );
      }
    }

    setState(() => isMerging = false);
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
