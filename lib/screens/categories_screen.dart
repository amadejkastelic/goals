import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/categories_provider.dart';
import '../widgets/status_widgets.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoriesProvider>().loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: SafeArea(
        child: Consumer<CategoriesProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const LoadingWidget(message: 'Loading categories...');
            }

            if (provider.error != null) {
              return ErrorDisplayWidget(
                message: provider.error!,
                onRetry: () {
                  provider.clearError();
                  provider.loadCategories();
                },
              );
            }

            if (provider.categories.isEmpty) {
              return EmptyStateWidget(
                icon: Icons.category_outlined,
                title: 'No categories',
                description: 'Add your first category to organize your goals.',
                actionLabel: 'Add Category',
                onAction: () => _showAddDialog(context),
              );
            }

            return RefreshIndicator(
              onRefresh: () => provider.loadCategories(),
              child: ListView.builder(
                itemCount: provider.categories.length,
                itemBuilder: (context, index) {
                  final category = provider.categories[index];
                  return _buildCategoryTile(context, category, provider);
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryTile(
    BuildContext context,
    Category category,
    CategoriesProvider provider,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Text(
          category.emoji ?? '📁',
          style: const TextStyle(fontSize: 20),
        ),
      ),
      title: Text(category.name),
      subtitle: Text(category.isDefault ? 'Default' : 'Custom'),
      trailing: category.isDefault
          ? null
          : PopupMenuButton<String>(
              onSelected: (action) {
                if (action == 'edit') {
                  _showEditDialog(context, category);
                } else if (action == 'delete') {
                  _confirmDelete(context, category, provider);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
      onTap: category.isDefault
          ? null
          : () => _showEditDialog(context, category),
    );
  }

  void _showAddDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emojiController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emojiController,
              decoration: const InputDecoration(
                labelText: 'Emoji (optional)',
                border: OutlineInputBorder(),
                hintText: 'e.g., 🎯',
              ),
              maxLength: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;

              final category = Category(
                name: nameController.text.trim(),
                emoji: emojiController.text.trim().isEmpty
                    ? null
                    : emojiController.text.trim(),
                isDefault: false,
              );

              final success = await context
                  .read<CategoriesProvider>()
                  .addCategory(category);
              if (context.mounted) {
                Navigator.pop(context);
                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.read<CategoriesProvider>().error ??
                            'Failed to add category',
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, Category category) {
    final nameController = TextEditingController(text: category.name);
    final emojiController = TextEditingController(text: category.emoji);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emojiController,
              decoration: const InputDecoration(
                labelText: 'Emoji (optional)',
                border: OutlineInputBorder(),
                hintText: 'e.g., 🎯',
              ),
              maxLength: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;

              final updated = Category(
                id: category.id,
                name: nameController.text.trim(),
                emoji: emojiController.text.trim().isEmpty
                    ? null
                    : emojiController.text.trim(),
                isDefault: category.isDefault,
              );

              final success = await context
                  .read<CategoriesProvider>()
                  .updateCategory(updated);
              if (context.mounted) {
                Navigator.pop(context);
                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.read<CategoriesProvider>().error ??
                            'Failed to update category',
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Category category,
    CategoriesProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Delete "${category.name}"? Goals using this category will keep it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await provider.deleteCategory(category.id!);
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Failed to delete category'),
          ),
        );
      }
    }
  }
}
