// lib/src/page/tasks/task_list.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pi_farm/src/models/task.dart';
import 'package:pi_farm/src/page/tasks/task_detail.dart';

class TaskList extends StatelessWidget {
  final CollectionReference userTasksCollection;
  final DateTime selectedDate;

  const TaskList({
    Key? key,
    required this.userTasksCollection,
    required this.selectedDate,
  }) : super(key: key);

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'cao':
        return Colors.red;
      case 'trung bình':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: userTasksCollection
          .where('dueDate',
              isGreaterThanOrEqualTo:
                  DateTime(selectedDate.year, selectedDate.month, selectedDate.day))
          .where('dueDate',
              isLessThan: DateTime(
                  selectedDate.year, selectedDate.month, selectedDate.day + 1))
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Đã xảy ra lỗi'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Không có công việc nào trong ngày'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final task = Task.fromMap(doc.data() as Map<String, dynamic>, doc.id);
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(
                  task.title,
                  style: TextStyle(
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('HH:mm').format(task.dueDate)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: task.isCompleted ? Colors.green.shade100 : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        task.isCompleted ? 'Đã hoàn thành' : 'Đang thực hiện',
                        style: TextStyle(
                          fontSize: 12,
                          color: task.isCompleted ? Colors.green.shade700 : Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => TaskDetail.show(
                    context,
                    task,
                    userTasksCollection,
                  ),
                ),
                onTap: () => TaskDetail.show(
                  context,
                  task,
                  userTasksCollection,
                ),
              ),
            );
          },
        );
      },
    );
  }
}