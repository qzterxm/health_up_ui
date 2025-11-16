import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import '../services/file_service.dart';
import '../services/token_decoder.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<UserFile> userFiles = [];
  bool isLoading = false;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserFiles();
  }

  Future<void> _loadUserFiles() async {
    setState(() => isLoading = true);


    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("accessToken");


      if (token == null) {
        _showSnackBar("User not authenticated");
        return;
      }

      final userId = TokenService.getUserIdFromToken(token);
      debugPrint("Decoded userId: $userId");
      if (userId == null) {
        _showSnackBar("Failed to decode userId");
        return;
      }

      currentUserId = userId;

      final result = await FileService.getUserFiles(userId: userId);


      if (result["success"] == true) {
        final data = result["data"] as List<dynamic>;

        setState(() {
          userFiles = data.map((e) => UserFile.fromJson(e as Map<String, dynamic>)).toList();
        });
      } else {
        _showSnackBar(result["message"] ?? "Failed to load files");

      }
    } catch (e, stack) {
      _showSnackBar("Error retrieving files: $e");

    } finally {
      setState(() => isLoading = false);

    }
  }

  Future<void> _uploadFile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("accessToken");


    if (token == null) {
      _showSnackBar("User not authenticated");
      return;
    }

    final userId = TokenService.getUserIdFromToken(token);


    if (userId == null) {
      _showSnackBar("Could not decode userId");
      return;
    }

    currentUserId = userId;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result == null || result.files.single.path == null) {

      return;
    }

    setState(() => isLoading = true);

    final file = File(result.files.single.path!);


    final uploadResult = await FileService.uploadFile(
      userId: userId,
      file: file,
    );


    setState(() => isLoading = false);

    if (uploadResult["success"] == true) {
      _showSnackBar("File uploaded successfully");
      _loadUserFiles();
    } else {
      _showSnackBar(uploadResult["message"] ?? "Upload failed");
    }
  }


  Future<void> _downloadFile(UserFile file) async {
    if (currentUserId == null) return;

    setState(() {
      isLoading = true;
    });

    final result = await FileService.downloadFile(
      userId: currentUserId!,
      fileId: file.id,
    );

    setState(() {
      isLoading = false;
    });

    if (result["success"] == true) {
      final bytes = result["data"] as List<int>;
      final fileName = result["fileName"] as String;

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final savedFile = File(filePath);

      await savedFile.writeAsBytes(bytes);
      await OpenFile.open(filePath);

      _showSnackBar("File downloaded successfully");
    } else {
      _showSnackBar(result["message"] ?? "Download failed");
    }
  }

  Future<void> _deleteFile(UserFile file) async {
    if (currentUserId == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete File"),
          content: Text("Are you sure you want to delete ${file.fileName}?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      setState(() {
        isLoading = true;
      });

      final result = await FileService.deleteFile(
        userId: currentUserId!,
        fileId: file.id,
      );

      setState(() {
        isLoading = false;
      });

      if (result["success"] == true) {
        _showSnackBar("File deleted successfully");
        _loadUserFiles();
      } else {
        _showSnackBar(result["message"] ?? "Delete failed");
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Latest files",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16.0),

                if (userFiles.isEmpty && !isLoading)
                  Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16.0),
                        const Text(
                          "No files uploaded yet",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          "Upload your first file to get started",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),

                ...userFiles.map((file) => Column(
                  children: [
                    _buildReportTile(file),
                    const SizedBox(height: 12.0),
                  ],
                )),

                const SizedBox(height: 24.0),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _uploadFile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    child: const Text(
                      'Add file',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 12.0),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loadUserFiles,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    child: const Text(
                      'Refresh files',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        if (isLoading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  Widget _buildReportTile(UserFile file) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Icon(_getFileIcon(file.contentType), color: Colors.blue.shade600),
        ),
        title: Text(
          file.fileName,
          style: const TextStyle(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
            _formatDate(file.uploadedAt),
            style: TextStyle(color: Colors.grey[600])
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_horiz, color: Colors.grey[600]),
          onSelected: (value) {
            if (value == 'download') {
              _downloadFile(file);
            } else if (value == 'delete') {
              _deleteFile(file);
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'download',
              child: Row(
                children: [
                  Icon(Icons.download, size: 20),
                  SizedBox(width: 8),
                  Text('Download'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _downloadFile(file),
      ),
    );
  }

  IconData _getFileIcon(String contentType) {
    if (contentType.contains('pdf')) {
      return Icons.picture_as_pdf;
    } else if (contentType.contains('image')) {
      return Icons.image;
    } else if (contentType.contains('word') || contentType.contains('document')) {
      return Icons.description;
    } else if (contentType.contains('video')) {
      return Icons.video_file;
    } else if (contentType.contains('audio')) {
      return Icons.audio_file;
    } else if (contentType.contains('zip') || contentType.contains('rar')) {
      return Icons.folder_zip;
    } else {
      return Icons.insert_drive_file;
    }
  }
}