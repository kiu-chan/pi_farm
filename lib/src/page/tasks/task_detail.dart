// lib/src/page/tasks/task_detail.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pi_farm/src/models/task.dart';

class TaskDetail {
  static void show(
    BuildContext context,
    Task task,
    CollectionReference collection,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _TaskDetailContent(
        task: task,
        collection: collection,
      ),
    );
  }
}

class _TaskDetailContent extends StatelessWidget {
  final Task task;
  final CollectionReference collection;

  const _TaskDetailContent({
    Key? key,
    required this.task,
    required this.collection,
  }) : super(key: key);

  Future<void> _toggleTaskStatus(BuildContext context) async {
    if (!task.isCompleted) {
      // Hiển thị dialog xác nhận khi đánh dấu hoàn thành
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Xác nhận hoàn thành'),
          content: Text('Bạn có chắc chắn "${task.title}" đã hoàn thành không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    await collection.doc(task.id).update({
      'isCompleted': !task.isCompleted,
    });
    Navigator.pop(context);
  }

  Future<void> _deleteTask(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa "${task.title}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await collection.doc(task.id).delete();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề
          Text(
            task.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Trạng thái
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: task.isCompleted ? Colors.green.shade100 : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              task.isCompleted ? 'Đã hoàn thành' : 'Đang thực hiện',
              style: TextStyle(
                color: task.isCompleted ? Colors.green.shade700 : Colors.orange.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Thông tin chi tiết
          const Text(
            'Thông tin chi tiết',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    'Thời gian:',
                    DateFormat('HH:mm dd/MM/yyyy').format(task.dueDate),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow('Người thực hiện:', task.assignedTo),
                  const SizedBox(height: 8),
                  _buildInfoRow('Độ ưu tiên:', task.priority),
                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow('Mô tả:', task.description),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Các nút hành động
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _toggleTaskStatus(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: task.isCompleted ? Colors.orange : Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: Icon(
                    task.isCompleted ? Icons.replay : Icons.check_circle,
                    color: Colors.white,
                  ),
                  label: Text(
                    task.isCompleted ? 'Đánh dấu chưa hoàn thành' : 'Đánh dấu hoàn thành',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _deleteTask(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
                icon: const Icon(Icons.delete, color: Colors.white),
                label: const Text(
                  'Xóa',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }
}