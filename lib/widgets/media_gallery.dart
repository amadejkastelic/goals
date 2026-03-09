import 'package:flutter/material.dart';
import '../models/media_attachment.dart';

class MediaGallery extends StatelessWidget {
  final List<MediaAttachment> attachments;
  final void Function(int mediaId)? onDelete;

  const MediaGallery({super.key, required this.attachments, this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: attachments.length,
        itemBuilder: (context, index) {
          final attachment = attachments[index];
          return _buildMediaItem(context, attachment);
        },
      ),
    );
  }

  Widget _buildMediaItem(BuildContext context, MediaAttachment attachment) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => _showMediaPreview(context, attachment),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildThumbnail(attachment),
            ),
          ),
          if (onDelete != null)
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => onDelete!(attachment.id!),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(MediaAttachment attachment) {
    if (attachment.type == 'image') {
      return Image.memory(
        attachment.data,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
      );
    }

    return Container(
      width: 100,
      height: 100,
      color: Colors.grey.shade300,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            attachment.type == 'video' ? Icons.videocam : Icons.audiotrack,
            size: 32,
            color: Colors.grey.shade600,
          ),
          const SizedBox(height: 4),
          Text(
            attachment.type.toUpperCase(),
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  void _showMediaPreview(BuildContext context, MediaAttachment attachment) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(
                attachment.type[0].toUpperCase() + attachment.type.substring(1),
              ),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Flexible(child: _buildPreviewContent(attachment)),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewContent(MediaAttachment attachment) {
    if (attachment.type == 'image') {
      return InteractiveViewer(
        child: Image.memory(attachment.data, fit: BoxFit.contain),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            attachment.type == 'video' ? Icons.videocam : Icons.audiotrack,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            '${attachment.type[0].toUpperCase()}${attachment.type.substring(1)} file',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '${(attachment.data.length / 1024).toStringAsFixed(1)} KB',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
