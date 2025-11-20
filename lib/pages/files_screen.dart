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
  List<UserNote> userNotes = [];
  bool isLoading = false;
  String? currentUserId;

  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("accessToken");

      if (token == null) {
        _showSnackBar("User not authenticated");
        return;
      }

      final userId = TokenService.getUserIdFromToken(token);
      if (userId == null) {
        _showSnackBar("Failed to decode userId");
        return;
      }
      currentUserId = userId;

      final fileResult = await FileService.getUserFiles(userId: userId, token: token);

      final noteResult = await NoteService.getNotes(userId: userId);

      setState(() {
        if (fileResult["success"] == true) {
          final data = fileResult["data"] as List<dynamic>;
          userFiles = data.map((e) => UserFile.fromJson(e as Map<String, dynamic>)).toList();
        } else {
          _showSnackBar(fileResult["message"] ?? "Failed to load files");
        }

        if (noteResult["success"] == true) {
          final data = noteResult["data"] as List<dynamic>;
          userNotes = data.map((e) => UserNote.fromJson(e as Map<String, dynamic>)).toList();
          userNotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        } else {
          _showSnackBar(noteResult["message"] ?? "Failed to load notes");
        }
      });
    } catch (e) {
      _showSnackBar("Error retrieving data: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }


  Future<void> _addNote() async {
    if (currentUserId == null) return;
    final text = _noteController.text.trim();
    if (text.isEmpty) {
      _showSnackBar("Please enter some text");
      return;
    }

    setState(() => isLoading = true);

    final result = await NoteService.addNote(userId: currentUserId!, text: text);

    setState(() => isLoading = false);

    if (result["success"] == true) {
      _noteController.clear();
      FocusScope.of(context).unfocus();
      _showSnackBar("Note added");
      _loadData();
    } else {
      _showSnackBar(result["message"] ?? "Failed to add note");
    }
  }

  Future<void> _deleteNote(UserNote note) async {
    if (currentUserId == null) return;
    final confirm = await _showConfirmationDialog("Delete Note", "Are you sure you want to delete this note?");
    if (confirm != true) return;

    setState(() => isLoading = true);
    final result = await NoteService.deleteNote(userId: currentUserId!, noteId: note.id);
    setState(() => isLoading = false);

    if (result["success"] == true) {
      _showSnackBar("Note deleted");
      _loadData();
    } else {
      _showSnackBar(result["message"] ?? "Failed to delete note");
    }
  }



  Future<void> _uploadFile() async {
    if (currentUserId == null) return;

    final result = await FilePicker.platform.pickFiles(type: FileType.any, allowMultiple: false);
    if (result == null || result.files.single.path == null) return;

    setState(() => isLoading = true);
    final file = File(result.files.single.path!);

    final uploadResult = await FileService.uploadFile(userId: currentUserId!, file: file);

    setState(() => isLoading = false);

    if (uploadResult["success"] == true) {
      _showSnackBar("File uploaded successfully");
      _loadData();
    } else {
      _showSnackBar(uploadResult["message"] ?? "Upload failed");
    }
  }

  Future<void> _downloadFile(UserFile file) async {
    if (currentUserId == null) return;
    setState(() => isLoading = true);

    final result = await FileService.downloadFile(userId: currentUserId!, fileId: file.id);
    setState(() => isLoading = false);

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
    final confirm = await _showConfirmationDialog("Delete File", "Are you sure you want to delete ${file.fileName}?");
    if (confirm != true) return;

    setState(() => isLoading = true);
    final result = await FileService.deleteFile(userId: currentUserId!, fileId: file.id);
    setState(() => isLoading = false);

    if (result["success"] == true) {
      _showSnackBar("File deleted");
      _loadData();
    } else {
      _showSnackBar(result["message"] ?? "Delete failed");
    }
  }

  Future<bool?> _showConfirmationDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")
          ),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 3)
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              Text(
                "Latest Files",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 16.0),

              if (userFiles.isEmpty && !isLoading)
                _buildEmptyFilesPlaceholder(),

              ...userFiles.map((file) => Column(
                children: [
                  _buildReportTile(file),
                  const SizedBox(height: 12.0),
                ],
              )),

              const SizedBox(height: 24.0),
              Divider(
                thickness: 1,
                height: 24,
                color: Theme.of(context).dividerColor,
              ),

              _buildActionButtons(),
              const SizedBox(height: 24.0),

              Text(
                "My Notes",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 10),
              _buildNoteInput(),
              const SizedBox(height: 16),
              if (userNotes.isEmpty && !isLoading)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "No notes yet.",
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                    ),
                  ),
                )
              else
                ...userNotes.map((note) => _buildNoteTile(note)),

              const SizedBox(height: 24.0),
            ],
          ),
        ),

        if (isLoading)
          Container(
            color: Colors.black54,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildEmptyFilesPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.folder_open,
            size: 64,
            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4),
          ),
          const SizedBox(height: 16.0),
          Text(
            "No files uploaded yet",
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            "Upload your first file to get started",
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _uploadFile,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
            ),
            child: const Text('Add file', style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
        ),
        const SizedBox(height: 12.0),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
            ),
            child: const Text('Refresh data', style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildReportTile(UserFile file) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Icon(
            _getFileIcon(file.contentType ?? ""),
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          file.fileName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _formatDate(file.uploadedAt),
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(
            Icons.more_horiz,
            color: Theme.of(context).iconTheme.color,
          ),
          onSelected: (value) {
            if (value == 'download') _downloadFile(file);
            else if (value == 'delete') _deleteFile(file);
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'download',
              child: Row(
                children: [
                  Icon(Icons.download, size: 20, color: Theme.of(context).iconTheme.color),
                  const SizedBox(width: 8),
                  Text(
                    'Download',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    'Delete',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _downloadFile(file),
      ),
    );
  }

  Widget _buildNoteInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _noteController,
            decoration: InputDecoration(
              hintText: "Write a note...",
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              hintStyle: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
              ),
            ),
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            maxLines: null,
          ),
        ),
        const SizedBox(width: 10),
        FloatingActionButton.small(
          onPressed: _addNote,
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(Icons.send, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildNoteTile(UserNote note) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(note.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                  ),
                ),
                InkWell(
                  onTap: () => _deleteNote(note),
                  child: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Colors.red,
                  ),
                )
              ],
            ),
            const SizedBox(height: 6),
            Text(
              note.noteText,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}