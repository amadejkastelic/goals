import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../models/journal_entry.dart';
import '../models/media_attachment.dart';
import '../models/custom_field_definition.dart';
import '../providers/journal_provider.dart';
import '../providers/custom_fields_provider.dart';
import '../widgets/media_gallery.dart';
import '../widgets/custom_field_input.dart';

class JournalEntryScreen extends StatefulWidget {
  final int goalId;
  final int dayNumber;
  final DateTime date;
  final JournalEntry? existingEntry;

  const JournalEntryScreen({
    super.key,
    required this.goalId,
    required this.dayNumber,
    required this.date,
    this.existingEntry,
  });

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _contentController;
  String? _selectedMood;
  final List<String> _moodEmojis = ['😞', '😟', '😐', '🙂', '😊'];
  final ImagePicker _picker = ImagePicker();
  JournalEntry? _savedEntry;
  bool _isSaving = false;
  final List<CustomFieldDefinition> _fieldDefinitions = [];
  final Map<int, String> _fieldValues = {};

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(
      text: widget.existingEntry?.content ?? '',
    );
    _selectedMood = widget.existingEntry?.moodEmoji;
    _savedEntry = widget.existingEntry;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomFieldsProvider>().loadDefinitionsForGoal(
        widget.goalId,
      );
      if (widget.existingEntry?.id != null) {
        context.read<JournalProvider>().loadMediaForEntry(
          widget.existingEntry!.id!,
        );
        context.read<CustomFieldsProvider>().loadValuesForEntry(
          widget.existingEntry!.id!,
        );
      }
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(
        title: Text('Day ${widget.dayNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveEntry,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateFormat.format(widget.date),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              Text(
                'How are you feeling?',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              _buildMoodSelector(),
              const SizedBox(height: 24),
              Text('Notes', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contentController,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: 'Write about your day...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Consumer<CustomFieldsProvider>(
                builder: (context, provider, _) {
                  final definitions = provider.getDefinitionsForGoal(
                    widget.goalId,
                  );
                  if (definitions.isEmpty) return const SizedBox.shrink();

                  if (_fieldDefinitions.isEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() => _fieldDefinitions.addAll(definitions));
                      if (widget.existingEntry?.id != null) {
                        final values = provider.getValuesForEntry(
                          widget.existingEntry!.id!,
                        );
                        for (final v in values) {
                          _fieldValues[v.definitionId] = v.value;
                        }
                      }
                    });
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        'Custom Fields',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 12),
                      ...definitions.map((def) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: CustomFieldInput(
                            definition: def,
                            initialValue: _fieldValues[def.id],
                            onChanged: (value) {
                              _fieldValues[def.id!] = value;
                            },
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Text('Media', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 12),
              _buildMediaButtons(),
              if (_savedEntry?.id != null) ...[
                const SizedBox(height: 16),
                Consumer<JournalProvider>(
                  builder: (context, provider, _) {
                    final media = provider.getMediaForEntry(_savedEntry!.id!);
                    if (media.isEmpty) return const SizedBox.shrink();
                    return MediaGallery(
                      attachments: media,
                      onDelete: (mediaId) => _deleteMedia(mediaId),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _moodEmojis.map((emoji) {
        final isSelected = _selectedMood == emoji;
        return GestureDetector(
          onTap: () => setState(() => _selectedMood = emoji),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                  : null,
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                  : null,
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 32)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMediaButtons() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.camera_alt),
          label: const Text('Camera'),
          onPressed: () => _pickImage(ImageSource.camera),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.photo_library),
          label: const Text('Gallery'),
          onPressed: () => _pickImage(ImageSource.gallery),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.attach_file),
          label: const Text('File'),
          onPressed: _pickFile,
        ),
      ],
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_savedEntry?.id == null) {
      await _saveEntry();
      if (_savedEntry?.id == null) return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      await _addMedia('image', bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  Future<void> _pickFile() async {
    if (_savedEntry?.id == null) {
      await _saveEntry();
      if (_savedEntry?.id == null) return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'mp4', 'mp3', 'wav'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null) return;

      String type = 'file';
      final ext = file.extension?.toLowerCase();
      if (['jpg', 'jpeg', 'png', 'gif'].contains(ext)) {
        type = 'image';
      } else if (ext == 'mp4') {
        type = 'video';
      } else if (['mp3', 'wav'].contains(ext)) {
        type = 'audio';
      }

      await _addMedia(type, file.bytes!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick file: $e')));
      }
    }
  }

  Future<void> _addMedia(String type, Uint8List data) async {
    if (_savedEntry?.id == null) return;

    final attachment = MediaAttachment(
      journalEntryId: _savedEntry!.id!,
      type: type,
      data: data,
      createdAt: DateTime.now(),
    );

    final success = await context.read<JournalProvider>().addMedia(attachment);
    if (!success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to add media')));
    }
  }

  Future<void> _deleteMedia(int mediaId) async {
    if (_savedEntry?.id == null) return;
    await context.read<JournalProvider>().deleteMedia(
      _savedEntry!.id!,
      mediaId,
    );
  }

  Future<void> _saveEntry() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final entry = JournalEntry(
        id: widget.existingEntry?.id ?? _savedEntry?.id,
        goalId: widget.goalId,
        dayNumber: widget.dayNumber,
        date: widget.date,
        content: _contentController.text.isEmpty
            ? null
            : _contentController.text,
        moodEmoji: _selectedMood,
      );

      final saved = await context.read<JournalProvider>().saveEntry(entry);
      setState(() => _savedEntry = saved);

      if (saved?.id != null && _fieldValues.isNotEmpty) {
        if (!mounted) return;
        final customFieldsProvider = context.read<CustomFieldsProvider>();
        await customFieldsProvider.saveAllValuesForEntry(
          saved!.id!,
          _fieldValues,
        );
      }

      if (mounted && saved != null) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
