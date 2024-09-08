import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AnimalDetailsPage extends StatefulWidget {
  final String animalId;

  const AnimalDetailsPage({Key? key, required this.animalId}) : super(key: key);

  @override
  _AnimalDetailsPageState createState() => _AnimalDetailsPageState();
}

class _AnimalDetailsPageState extends State<AnimalDetailsPage> {
  late Stream<DocumentSnapshot> animalStream;
  late Stream<DocumentSnapshot> medicalHistoryStream;

  @override
  void initState() {
    super.initState();
    animalStream = FirebaseFirestore.instance
        .collection('farm_animals')
        .doc(widget.animalId)
        .snapshots();
    medicalHistoryStream = FirebaseFirestore.instance
        .collection('medical_histories')
        .doc(widget.animalId)
        .snapshots();
  }

  String calculateAge(String? birthDateString) {
    if (birthDateString == null) return 'Chưa có thông tin';
    final birthDate = DateFormat('dd/MM/yyyy').parse(birthDateString);
    final now = DateTime.now();
    final difference = now.difference(birthDate);
    final days = difference.inDays;
    final months = days ~/ 30;
    final years = days ~/ 365;

    if (years > 0) {
      return '$years năm ${months % 12} tháng';
    } else if (months > 0) {
      return '$months tháng ${days % 30} ngày';
    } else {
      return '$days ngày';
    }
  }

  Widget _buildInfoField(String label, String? value) {
    return ListTile(
      title: Text(label),
      subtitle: Text(value ?? 'Chưa có thông tin'),
      trailing: IconButton(
        icon: Icon(Icons.edit),
        onPressed: () async {
          final newValue = await showDialog<String>(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: Text('Chỉnh sửa $label'),
              content: TextField(
                decoration: InputDecoration(hintText: "Nhập $label mới"),
                controller: TextEditingController(text: value),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, value),
                  child: const Text('Lưu'),
                ),
              ],
            ),
          );
          if (newValue != null && newValue != value) {
            FirebaseFirestore.instance
                .collection('farm_animals')
                .doc(widget.animalId)
                .update({label.toLowerCase(): newValue});
          }
        },
      ),
    );
  }

  Widget _buildMedicalHistoryList() {
    return StreamBuilder<DocumentSnapshot>(
      stream: medicalHistoryStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Đã xảy ra lỗi: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        final medicalHistoryData =
            snapshot.data?.data() as Map<String, dynamic>? ?? {};

        if (medicalHistoryData.isEmpty) {
          return Text('Chưa có lịch sử khám');
        }

        List<MapEntry<String, dynamic>> sortedEntries =
            medicalHistoryData.entries.toList()
              ..sort((a, b) {
                final createdAtA = a.value['created_at'] as Timestamp?;
                final createdAtB = b.value['created_at'] as Timestamp?;

                if (createdAtA == null && createdAtB == null) {
                  return 0;
                } else if (createdAtA == null) {
                  return 1;
                } else if (createdAtB == null) {
                  return -1;
                } else {
                  return createdAtB.compareTo(createdAtA);
                }
              });

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: sortedEntries.length,
          itemBuilder: (context, index) {
            final entry = sortedEntries[index];
            final record = entry.value as Map<String, dynamic>?;
            final createdAt = record?['created_at'] as Timestamp?;
            return ListTile(
              title: Text(
                createdAt != null
                    ? 'Ngày khám: ${DateFormat('dd/MM/yyyy').format(createdAt.toDate())}'
                    : 'Ngày khám: Không có thông tin',
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'Chẩn đoán: ${record?['diagnosis'] ?? 'Chưa có thông tin'}'),
                  Text(
                      'Triệu chứng: ${record?['symptoms'] ?? 'Chưa có thông tin'}'),
                  Text(
                      'Điều trị: ${record?['treatment'] ?? 'Chưa có thông tin'}'),
                  Text(
                      'Bác sĩ: ${record?['veterinarian'] ?? 'Chưa có thông tin'}'),
                  Text(
                      'Tình trạng hiện tại: ${record?['current_status'] ?? 'Chưa có thông tin'}'),
                  Text('Ghi chú: ${record?['note'] ?? 'Chưa có thông tin'}'),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddMedicalHistoryDialog() {
    String diagnosis = '';
    String symptoms = '';
    String treatment = '';
    String veterinarian = '';
    String currentStatus = '';
    String note = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Thêm lịch sử khám'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(labelText: 'Chẩn đoán'),
                  onChanged: (value) => diagnosis = value,
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Triệu chứng'),
                  onChanged: (value) => symptoms = value,
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Điều trị'),
                  onChanged: (value) => treatment = value,
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Bác sĩ'),
                  onChanged: (value) => veterinarian = value,
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Tình trạng hiện tại'),
                  onChanged: (value) => currentStatus = value,
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Ghi chú'),
                  onChanged: (value) => note = value,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Hủy'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Lưu'),
              onPressed: () {
                _addMedicalHistory(
                  diagnosis: diagnosis,
                  symptoms: symptoms,
                  treatment: treatment,
                  veterinarian: veterinarian,
                  currentStatus: currentStatus,
                  note: note,
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _addMedicalHistory({
    required String diagnosis,
    required String symptoms,
    required String treatment,
    required String veterinarian,
    required String currentStatus,
    required String note,
  }) {
    final newMedicalRecord = {
      'created_at': FieldValue.serverTimestamp(),
      'diagnosis': diagnosis,
      'symptoms': symptoms,
      'treatment': treatment,
      'veterinarian': veterinarian,
      'current_status': currentStatus,
      'note': note,
    };

    FirebaseFirestore.instance
        .collection('medical_histories')
        .doc(widget.animalId)
        .set({
      DateTime.now().millisecondsSinceEpoch.toString(): newMedicalRecord
    }, SetOptions(merge: true)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã thêm lịch sử khám mới')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi thêm lịch sử khám: $error')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chi tiết vật nuôi')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: animalStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Đã xảy ra lỗi'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final animalData = snapshot.data?.data() as Map<String, dynamic>?;

          if (animalData == null) {
            return Center(child: Text('Không tìm thấy thông tin vật nuôi'));
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoField('Tên', animalData['name'] as String?),
                ListTile(
                  title: Text('Mã'),
                  subtitle: Text(widget.animalId),
                ),
                _buildInfoField(
                    'Ngày sinh', animalData['birthDate'] as String?),
                ListTile(
                  title: Text('Tuổi'),
                  subtitle:
                      Text(calculateAge(animalData['birthDate'] as String?)),
                ),
                Divider(),
                Text('Lịch sử khám',
                    style: Theme.of(context).textTheme.titleLarge),
                _buildMedicalHistoryList(),
                ElevatedButton(
                  child: Text('Thêm lịch sử khám'),
                  onPressed: _showAddMedicalHistoryDialog,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
