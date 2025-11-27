import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../services/file_service.dart';
import '../services/token_decoder.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  List<UserNote> userNotes = [];
  List<UserFile> allUserFiles = [];
  bool isLoading = false;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (isLoading) return;

    if (mounted) setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("accessToken");

      if (token == null) {
        if (mounted) _showSnackBar("User not authenticated");
        return;
      }

      final userId = TokenService.getUserIdFromToken(token);
      if (userId == null) {
        if (mounted) _showSnackBar("Failed to decode userId");
        return;
      }
      currentUserId = userId;

      final results = await Future.wait([
        NoteService.getNotes(userId: userId),
        FileService.getUserFiles(userId: userId, token: token),
      ]);

      final noteResult = results[0];
      final fileResult = results[1];

      if (mounted) {
        setState(() {
          if (noteResult["success"] == true) {
            final data = noteResult["data"] as List<dynamic>;
            userNotes = data.map((e) => UserNote.fromJson(e as Map<String, dynamic>)).toList();
            userNotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          } else {
            _showSnackBar(noteResult["message"] ?? "Failed to load notes");
          }

          if (fileResult["success"] == true) {
            final data = fileResult["data"] as List<dynamic>;
            allUserFiles = data.map((e) => UserFile.fromJson(e as Map<String, dynamic>)).toList();
          }
        });
      }
    } catch (e) {
      if (mounted) _showSnackBar("Error retrieving data: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _onRefresh() async {
    if (isLoading && mounted) setState(() => isLoading = false);
    await _loadData();
  }


  Future<void> _showAddNoteDialog() async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController noteController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          "New Health Note",
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: "Title (e.g., Blood Test)",
                  hintStyle: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Theme.of(context).cardColor.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  hintText: "Describe symptoms, results, etc...",
                  hintStyle: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Theme.of(context).cardColor.withOpacity(0.5),
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty && noteController.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(context);
              await _createNote(
                  titleController.text.trim(),
                  noteController.text.trim()
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text("Save Note", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _createNote(String title, String text) async {
    if (currentUserId == null) return;

    if (mounted) setState(() => isLoading = true);

    final result = await NoteService.addNote(
        userId: currentUserId!,
        title: title,
        text: text
    );

    if (mounted) setState(() => isLoading = false);

    await _loadData();

    if (result["success"] == true) {
    } else {
      _showSnackBar(result["message"] ?? "Failed to create note");
    }
  }

  Future<void> _attachFileToNote(UserNote note) async {
    if (currentUserId == null) return;

    final result = await FilePicker.platform.pickFiles(type: FileType.any, allowMultiple: false);
    if (result == null || result.files.single.path == null) return;

    if (mounted) setState(() => isLoading = true);

    final file = File(result.files.single.path!);

    final uploadResult = await FileService.uploadFile(
        userId: currentUserId!,
        file: file,
        noteId: note.id
    );

    if (mounted) setState(() => isLoading = false);

    await _loadData();

    if (uploadResult["success"] == true) {
      _showSnackBar("File attached successfully");
    } else {
      _showSnackBar(uploadResult["message"] ?? "Upload failed");
    }
  }

  Future<void> _deleteNote(UserNote note) async {
    final confirm = await _showConfirmationDialog("Delete Note", "Delete this note and its files?");
    if (confirm != true) return;

    if (mounted) setState(() => isLoading = true);

    final result = await NoteService.deleteNote(userId: currentUserId!, noteId: note.id);

    if (mounted) setState(() => isLoading = false);

    await _loadData();

    if (result["success"] == true) {
      _showSnackBar("Note deleted");
    } else {
      _showSnackBar(result["message"] ?? "Failed to delete note");
    }
  }

  Future<void> _downloadFile(UserFile file) async {
    if (currentUserId == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Downloading..."), duration: Duration(seconds: 1))
    );

    final result = await FileService.downloadFile(userId: currentUserId!, fileId: file.id);

    if (result["success"] == true) {
      final bytes = result["data"] as List<int>;
      final fileName = result["fileName"] as String;
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final savedFile = File(filePath);
      await savedFile.writeAsBytes(bytes);
      await OpenFile.open(filePath);
    } else {
      _showSnackBar(result["message"] ?? "Download failed");
    }
  }

  Future<void> _deleteFile(UserFile file) async {
    if (currentUserId == null) return;
    final confirm = await _showConfirmationDialog("Delete File", "Are you sure you want to delete this file?");
    if (confirm != true) return;

    if (mounted) setState(() => isLoading = true);

    final result = await FileService.deleteFile(userId: currentUserId!, fileId: file.id);

    if (mounted) setState(() => isLoading = false);

    await _loadData();

    if (result["success"] == true) {
      _showSnackBar("File deleted");
    } else {
      _showSnackBar(result["message"] ?? "Delete failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddNoteDialog,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.note_add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: Theme.of(context).colorScheme.primary,
        child: Stack(
          children: [
            if (userNotes.isEmpty && !isLoading)
              _buildEmptyState()
            else
              ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
                itemCount: userNotes.length,
                itemBuilder: (context, index) {
                  final note = userNotes[index];
                  return _buildNoteCard(note);
                },
              ),
            if (isLoading)
              Container(
                color: userNotes.isEmpty
                    ? Theme.of(context).scaffoldBackgroundColor
                    : Colors.black.withOpacity(0.1),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.note_alt_outlined,
                size: 64,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4),
              ),
              const SizedBox(height: 16),
              Text(
                "No notes recorded yet",
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Tap the + button to create a note",
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoteCard(UserNote note) {
    final attachedFiles = allUserFiles.where((f) => f.noteId == note.id).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Theme.of(context).cardColor,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: Icon(Icons.description, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(
          note.noteTitle.isNotEmpty ? note.noteTitle : "Untitled Note",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              _formatDate(note.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
              ),
            ),
            if (note.noteText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  note.noteText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                  ),
                ),
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                if (note.noteText.isNotEmpty)
                  Text(
                    note.noteText,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),

                const SizedBox(height: 16),
                Divider(color: Theme.of(context).dividerColor.withOpacity(0.5)),

                if (attachedFiles.isNotEmpty) ...[
                  Text(
                    "Attachments (${attachedFiles.length})",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...attachedFiles.map((file) => _buildFileTile(file)),
                ] else
                  Text(
                    "No files attached",
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                    ),
                  ),

                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _attachFileToNote(note),
                      icon: const Icon(Icons.attach_file, size: 18),
                      label: const Text("Attach File"),
                      style: TextButton.styleFrom(foregroundColor: Colors.blue),
                    ),
                    TextButton.icon(
                      onPressed: () => _deleteNote(note),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text("Delete"),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileTile(UserFile file) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3)),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        leading: Icon(
            _getFileIcon(file.contentType ?? ""),
            color: Theme.of(context).colorScheme.primary,
            size: 24
        ),
        title: Text(
          file.fileName,
          style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyLarge?.color
          ),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.download_rounded, size: 20),
              color: Colors.grey,
              onPressed: () => _downloadFile(file),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              color: Colors.red.shade300,
              onPressed: () => _deleteFile(file),
            ),
          ],
        ),
      ),
    );
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
            duration: const Duration(seconds: 3),
            backgroundColor: Theme.of(context).colorScheme.primary
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  IconData _getFileIcon(String contentType) {
    if (contentType.contains('pdf')) return Icons.picture_as_pdf;
    if (contentType.contains('image')) return Icons.image;
    if (contentType.contains('word') || contentType.contains('document')) return Icons.description;
    if (contentType.contains('video')) return Icons.video_file;
    if (contentType.contains('audio')) return Icons.audio_file;
    return Icons.insert_drive_file;
  }
}