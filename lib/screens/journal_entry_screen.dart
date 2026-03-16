import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../models/journal_entry.dart';
import '../models/media_attachment.dart';
import '../models/custom_field_definition.dart';
import '../models/custom_field_value.dart';
import '../providers/journal_provider.dart';
import '../providers/custom_fields_provider.dart';
import '../widgets/media_gallery.dart';
import '../widgets/custom_field_input.dart';
import '../models/mfp_nutrition.dart';
import '../widgets/mfp_nutrition_tile.dart';
import 'mfp_data_fetcher.dart';

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
  late bool _isEditing;
  final List<CustomFieldDefinition> _fieldDefinitions = [];
  final List<CustomFieldDefinition> _pendingEntrySpecificDefinitions = [];
  final Map<int, String> _fieldValues = {};

  @override
  void initState() {
    super.initState();
    _isEditing = widget.existingEntry == null;
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
        context.read<CustomFieldsProvider>().loadEntrySpecificDefinitions(
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Day ${widget.dayNumber}'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isSaving ? null : _saveEntry,
            )
          else
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: _isEditing ? _buildEditMode() : _buildViewMode(),
    );
  }

  Widget _buildViewMode() {
    final dateFormat = DateFormat.yMMMd();
    final hasContent = _contentController.text.isNotEmpty;
    final hasMood = _selectedMood != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateFormat.format(widget.date),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          if (hasMood) ...[
            Text('Mood', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            Text(_selectedMood!, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 24),
          ],
          if (hasContent) ...[
            Text('Notes', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            Text(_contentController.text),
            const SizedBox(height: 24),
          ],
          Consumer<CustomFieldsProvider>(
            builder: (context, provider, _) {
              final goalDefinitions = provider.getDefinitionsForGoal(
                widget.goalId,
              );
              final savedEntryDefinitions = _savedEntry?.id != null
                  ? provider.getEntrySpecificDefinitions(_savedEntry!.id!)
                  : <CustomFieldDefinition>[];

              final providerValues = _savedEntry?.id != null
                  ? provider.getValuesForEntry(_savedEntry!.id!)
                  : <CustomFieldValue>[];

              if (_fieldDefinitions.isEmpty && goalDefinitions.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  setState(() => _fieldDefinitions.addAll(goalDefinitions));
                });
              }

              final allDefinitions = [
                ...goalDefinitions,
                ...savedEntryDefinitions,
                ..._pendingEntrySpecificDefinitions,
              ];

              if (providerValues.isNotEmpty &&
                  providerValues.any(
                    (v) => !_fieldValues.containsKey(v.definitionId),
                  )) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  setState(() {
                    for (final v in providerValues) {
                      _fieldValues[v.definitionId] = v.value;
                    }
                  });
                });
              }

              final fieldsWithValues = allDefinitions.where((def) {
                return _fieldValues.containsKey(def.id) &&
                    _fieldValues[def.id]!.isNotEmpty;
              }).toList();

              if (fieldsWithValues.isEmpty) return const SizedBox.shrink();

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
                  ...fieldsWithValues.map((def) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: CustomFieldInput(
                        key: ValueKey('view_field_${def.id}'),
                        definition: def,
                        initialValue: _fieldValues[def.id],
                        onChanged: (_) {},
                        readOnly: true,
                      ),
                    );
                  }),
                ],
              );
            },
          ),
          if (_savedEntry?.mfpNutrition != null) ...[
            const SizedBox(height: 16),
            MFPNutritionTile(
              nutrition: _savedEntry!.mfpNutrition!,
              onRefresh: () => _importMFPNutrition(),
              onRemove: () => _removeMFPNutrition(),
            ),
          ],
          if (_savedEntry?.id != null)
            Consumer<JournalProvider>(
              builder: (context, provider, _) {
                final media = provider.getMediaForEntry(_savedEntry!.id!);
                if (media.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text('Media', style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 12),
                    MediaGallery(attachments: media),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEditMode() {
    final dateFormat = DateFormat.yMMMd();

    return Form(
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
            _buildMFPSection(),
            Consumer<CustomFieldsProvider>(
              builder: (context, provider, _) {
                final goalDefinitions = provider.getDefinitionsForGoal(
                  widget.goalId,
                );
                final savedEntryDefinitions = _savedEntry?.id != null
                    ? provider.getEntrySpecificDefinitions(_savedEntry!.id!)
                    : <CustomFieldDefinition>[];

                if (_fieldDefinitions.isEmpty && goalDefinitions.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() => _fieldDefinitions.addAll(goalDefinitions));
                  });
                }

                final allDefinitions = [
                  ...goalDefinitions,
                  ...savedEntryDefinitions,
                  ..._pendingEntrySpecificDefinitions,
                ];

                if (widget.existingEntry?.id != null) {
                  final providerValues = provider.getValuesForEntry(
                    widget.existingEntry!.id!,
                  );
                  final needsUpdate =
                      providerValues.isNotEmpty &&
                      providerValues.any(
                        (v) => !_fieldValues.containsKey(v.definitionId),
                      );
                  if (needsUpdate) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        for (final v in providerValues) {
                          _fieldValues[v.definitionId] = v.value;
                        }
                      });
                    });
                  }
                }

                if (allDefinitions.isEmpty) {
                  return TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Custom Field'),
                    onPressed: () => _showAddFieldDialog(),
                  );
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
                    ...allDefinitions.map((def) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: CustomFieldInput(
                          key: ValueKey(
                            'field_${def.id}_${_fieldValues[def.id]}',
                          ),
                          definition: def,
                          initialValue: _fieldValues[def.id],
                          onChanged: (value) {
                            _fieldValues[def.id!] = value;
                          },
                        ),
                      );
                    }),
                    TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Custom Field'),
                      onPressed: () => _showAddFieldDialog(),
                    ),
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

  Future<void> _showAddFieldDialog() async {
    final result = await showDialog<(String, CustomFieldType, List<String>)>(
      context: context,
      builder: (context) => _AddFieldDialog(),
    );

    if (result != null && mounted) {
      final (name, fieldType, options) = result;

      if (_savedEntry?.id != null) {
        final def = CustomFieldDefinition(
          journalEntryId: _savedEntry!.id!,
          name: name,
          fieldType: fieldType,
          options: options,
        );
        final success = await context
            .read<CustomFieldsProvider>()
            .addEntrySpecificDefinition(def);
        if (!success && mounted) {
          final provider = context.read<CustomFieldsProvider>();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(provider.error ?? 'Failed to add field')),
          );
        }
      } else {
        setState(() {
          final tempId = DateTime.now().millisecondsSinceEpoch;
          _pendingEntrySpecificDefinitions.add(
            CustomFieldDefinition(
              id: tempId,
              goalId: null,
              name: name,
              fieldType: fieldType,
              options: options,
            ),
          );
        });
      }
    }
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

  Widget _buildMFPSection() {
    if (_savedEntry?.mfpNutrition != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MFPNutritionTile(
            nutrition: _savedEntry!.mfpNutrition!,
            onRefresh: () => _importMFPNutrition(),
            onRemove: () => _removeMFPNutrition(),
          ),
        ],
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.restaurant),
        title: const Text('MyFitnessPal'),
        subtitle: const Text('Import nutrition data for this day'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _importMFPNutrition(),
      ),
    );
  }

  Future<void> _importMFPNutrition() async {
    if (_savedEntry?.id == null) {
      await _saveEntry();
      if (_savedEntry?.id == null) return;
    }

    final nutrition = await Navigator.of(context).push<MFPNutrition>(
      MaterialPageRoute(
        builder: (context) => MFPDataFetcher(date: widget.date),
      ),
    );

    if (nutrition != null && mounted) {
      debugPrint(
        'MFP import: got nutrition ${nutrition.calories} cal, ${nutrition.protein}g protein',
      );
      final updatedEntry = _savedEntry!.copyWith(mfpNutrition: nutrition);
      debugPrint(
        'MFP import: entry to save has nutrition: ${updatedEntry.mfpNutrition?.calories}',
      );
      final saved = await context.read<JournalProvider>().saveEntry(
        updatedEntry,
      );
      debugPrint(
        'MFP import: saved entry has nutrition: ${saved?.mfpNutrition?.calories}',
      );
      setState(() => _savedEntry = saved);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nutrition data imported')),
        );
      }
    }
  }

  Future<void> _removeMFPNutrition() async {
    if (_savedEntry?.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove nutrition data'),
        content: const Text(
          'Remove the imported nutrition data from this entry?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final updatedEntry = _savedEntry!.copyWith(
      mfpNutrition: const MFPNutrition(
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
      ),
    );
    final saved = await context
        .read<JournalProvider>()
        .saveEntryWithClearedNutrition(updatedEntry);
    setState(() => _savedEntry = saved);
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
        mfpNutrition: _savedEntry?.mfpNutrition,
      );

      final saved = await context.read<JournalProvider>().saveEntry(entry);
      setState(() => _savedEntry = saved);

      if (saved?.id != null) {
        if (!mounted) return;
        final customFieldsProvider = context.read<CustomFieldsProvider>();

        final tempIdToRealId = <int, int>{};

        for (final pendingDef in _pendingEntrySpecificDefinitions) {
          final newDef = CustomFieldDefinition(
            journalEntryId: saved!.id!,
            name: pendingDef.name,
            fieldType: pendingDef.fieldType,
            options: pendingDef.options,
          );
          await customFieldsProvider.addEntrySpecificDefinition(newDef);

          final newDefs = customFieldsProvider.getEntrySpecificDefinitions(
            saved.id!,
          );
          final createdDef = newDefs.firstWhere(
            (d) =>
                d.name == pendingDef.name &&
                d.fieldType == pendingDef.fieldType,
            orElse: () => newDef,
          );
          if (createdDef.id != null && pendingDef.id != null) {
            tempIdToRealId[pendingDef.id!] = createdDef.id!;
          }
        }

        final valuesToSave = <int, String>{};
        for (final entry in _fieldValues.entries) {
          final realId = tempIdToRealId[entry.key] ?? entry.key;
          valuesToSave[realId] = entry.value;
        }

        if (valuesToSave.isNotEmpty) {
          debugPrint(
            'Saving field values: $valuesToSave for entry ${saved?.id}',
          );
          await customFieldsProvider.saveAllValuesForEntry(
            saved!.id!,
            valuesToSave,
          );
        }
      }

      if (mounted && saved != null) {
        setState(() => _isEditing = false);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _AddFieldDialog extends StatefulWidget {
  @override
  State<_AddFieldDialog> createState() => _AddFieldDialogState();
}

class _AddFieldDialogState extends State<_AddFieldDialog> {
  final _nameController = TextEditingController();
  CustomFieldType _selectedType = CustomFieldType.text;
  final List<TextEditingController> _optionControllers = [];
  bool _needsOptions = false;

  @override
  void initState() {
    super.initState();
    _updateNeedsOptions();
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _updateNeedsOptions() {
    final needsOptions =
        _selectedType == CustomFieldType.checkboxes ||
        _selectedType == CustomFieldType.dropdown ||
        _selectedType == CustomFieldType.radio;
    if (needsOptions != _needsOptions) {
      setState(() {
        _needsOptions = needsOptions;
        if (_needsOptions && _optionControllers.isEmpty) {
          _optionControllers.add(TextEditingController());
        }
      });
    }
  }

  void _addOption() {
    setState(() => _optionControllers.add(TextEditingController()));
  }

  void _removeOption(int index) {
    setState(() {
      _optionControllers[index].dispose();
      _optionControllers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Custom Field'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Field Name',
                hintText: 'e.g., Sleep Hours',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<CustomFieldType>(
              initialValue: _selectedType,
              decoration: const InputDecoration(labelText: 'Field Type'),
              items: CustomFieldType.values.map((type) {
                String label;
                switch (type) {
                  case CustomFieldType.checkboxes:
                    label = 'Checkboxes';
                    break;
                  case CustomFieldType.text:
                    label = 'Text';
                    break;
                  case CustomFieldType.number:
                    label = 'Number';
                    break;
                  case CustomFieldType.date:
                    label = 'Date';
                    break;
                  case CustomFieldType.time:
                    label = 'Time';
                    break;
                  case CustomFieldType.dropdown:
                    label = 'Dropdown';
                    break;
                  case CustomFieldType.radio:
                    label = 'Radio Buttons';
                    break;
                  case CustomFieldType.rating:
                    label = 'Rating';
                    break;
                }
                return DropdownMenuItem(value: type, child: Text(label));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                  _updateNeedsOptions();
                }
              },
            ),
            if (_needsOptions) ...[
              const SizedBox(height: 16),
              Text('Options', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              ...List.generate(_optionControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _optionControllers[index],
                          decoration: InputDecoration(
                            labelText: 'Option ${index + 1}',
                            isDense: true,
                          ),
                        ),
                      ),
                      if (_optionControllers.length > 1)
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => _removeOption(index),
                        ),
                    ],
                  ),
                );
              }),
              TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Option'),
                onPressed: _addOption,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_nameController.text.isEmpty) return;
            if (_needsOptions) {
              final options = _optionControllers
                  .map((c) => c.text.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
              if (options.isEmpty) return;
              Navigator.pop(context, (
                _nameController.text.trim(),
                _selectedType,
                options,
              ));
            } else {
              Navigator.pop(context, (
                _nameController.text.trim(),
                _selectedType,
                <String>[],
              ));
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
