// lib/src/page/tasks/tasks_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pi_farm/src/models/task.dart';
import 'package:pi_farm/src/page/tasks/task_list.dart';
import 'package:pi_farm/src/page/tasks/task_detail.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({Key? key}) : super(key: key);

  @override
  TasksPageState createState() => TasksPageState();
}

class TasksPageState extends State<TasksPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  DateTime selectedDate = DateTime.now();
  late String userEmail;

  @override
  void initState() {
    super.initState();
    userEmail = _auth.currentUser?.email ?? '';
  }

  CollectionReference get userTasksCollection {
    return _firestore.collection('tasks').doc(userEmail).collection('user_tasks');
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Công việc hôm nay'),
        backgroundColor: const Color(0xFF64B5F6),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              DateFormat('dd/MM/yyyy').format(selectedDate),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: TaskList(
              userTasksCollection: userTasksCollection,
              selectedDate: selectedDate,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        backgroundColor: const Color(0xFF64B5F6),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddTaskDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final assignedToController = TextEditingController();
    DateTime selectedTime = DateTime.now();
    String selectedPriority = 'Bình thường';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm công việc mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Tiêu đề'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Mô tả'),
                maxLines: 3,
              ),
              TextField(
                controller: assignedToController,
                decoration: const InputDecoration(labelText: 'Người thực hiện'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Thời gian: '),
                  TextButton(
                    onPressed: () async {
                      final TimeOfDay? time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedTime),
                      );
                      if (time != null) {
                        selectedTime = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          time.hour,
                          time.minute,
                        );
                      }
                    },
                    child: Text(DateFormat('HH:mm').format(selectedTime)),
                  ),
                ],
              ),
              DropdownButtonFormField<String>(
                value: selectedPriority,
                items: ['Cao', 'Trung bình', 'Bình thường']
                    .map((priority) => DropdownMenuItem(
                          value: priority,
                          child: Text(priority),
                        ))
                    .toList(),
                onChanged: (value) {
                  selectedPriority = value!;
                },
                decoration: const InputDecoration(labelText: 'Độ ưu tiên'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty) {
                return;
              }

              final newTask = Task(
                id: '',
                title: titleController.text,
                description: descriptionController.text,
                dueDate: selectedTime,
                assignedTo: assignedToController.text,
                priority: selectedPriority,
              );

              await userTasksCollection.add(newTask.toMap());
              Navigator.pop(context);
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }
}