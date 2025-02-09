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

  // Định nghĩa các màu chủ đạo
  static const primaryColor = Color(0xFF64B5F6); // Xanh dương nhạt
  static const backgroundColor = Color(0xFFE3F2FD); // Nền xanh nhạt hơn
  static const accentColor = Color(0xFF1976D2); // Xanh đậm cho nhấn mạnh

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

  String _calculateAge(String? birthDateString) {
    if (birthDateString == null) return 'Chưa có thông tin';
    try {
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
    } catch (e) {
      return 'Định dạng ngày không hợp lệ';
    }
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField(String label, String? value, VoidCallback onEdit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              color: primaryColor,
              onPressed: onEdit,
            ),
          ],
        ),
        Text(
          value ?? 'Chưa có thông tin',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Divider(height: 24),
      ],
    );
  }

  void _showEditDialog(String title, String currentValue, Function(String) onSave) {
    String newValue = currentValue;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Chỉnh sửa $title'),
          content: TextField(
            decoration: InputDecoration(
              labelText: title,
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            controller: TextEditingController(text: currentValue),
            onChanged: (value) => newValue = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                onSave(newValue);
                Navigator.pop(context);
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMedicalHistoryList() {
    return StreamBuilder<DocumentSnapshot>(
      stream: medicalHistoryStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Đã xảy ra lỗi: ${snapshot.error}',
              style: TextStyle(color: Colors.red[700]),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          );
        }

        final medicalHistoryData = snapshot.data?.data() as Map<String, dynamic>? ?? {};

        if (medicalHistoryData.isEmpty) {
          return const Center(
            child: Text('Chưa có lịch sử khám bệnh'),
          );
        }

        List<MapEntry<String, dynamic>> sortedEntries = medicalHistoryData.entries.toList()
          ..sort((a, b) {
            final createdAtA = a.value['created_at'] as Timestamp?;
            final createdAtB = b.value['created_at'] as Timestamp?;
            if (createdAtA == null || createdAtB == null) return 0;
            return createdAtB.compareTo(createdAtA);
          });

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedEntries.length,
          itemBuilder: (context, index) {
            final entry = sortedEntries[index];
            final record = entry.value as Map<String, dynamic>;
            final createdAt = record['created_at'] as Timestamp?;
            
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
              child: ExpansionTile(
                title: Text(
                  createdAt != null
                      ? 'Ngày khám: ${DateFormat('dd/MM/yyyy').format(createdAt.toDate())}'
                      : 'Ngày khám: Không xác định',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMedicalInfoRow('Chẩn đoán', record['diagnosis']),
                        _buildMedicalInfoRow('Triệu chứng', record['symptoms']),
                        _buildMedicalInfoRow('Điều trị', record['treatment']),
                        _buildMedicalInfoRow('Bác sĩ', record['veterinarian']),
                        _buildMedicalInfoRow('Tình trạng', record['current_status']),
                        _buildMedicalInfoRow('Ghi chú', record['note']),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMedicalInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value ?? 'Chưa có thông tin'),
          ),
        ],
      ),
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
          title: const Text('Thêm lịch sử khám'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMedicalInputField('Chẩn đoán', (value) => diagnosis = value),
                const SizedBox(height: 16),
                _buildMedicalInputField('Triệu chứng', (value) => symptoms = value),
                const SizedBox(height: 16),
                _buildMedicalInputField('Điều trị', (value) => treatment = value),
                const SizedBox(height: 16),
                _buildMedicalInputField('Bác sĩ', (value) => veterinarian = value),
                const SizedBox(height: 16),
                _buildMedicalInputField('Tình trạng hiện tại', (value) => currentStatus = value),
                const SizedBox(height: 16),
                _buildMedicalInputField('Ghi chú', (value) => note = value),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Hủy'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Lưu'),
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

  Widget _buildMedicalInputField(String label, Function(String) onChanged) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      onChanged: onChanged,
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
      _showSuccessSnackBar('Đã thêm lịch sử khám mới');
    }).catchError((error) {
      _showErrorSnackBar('Lỗi khi thêm lịch sử khám: $error');
    });
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text(
          'Chi tiết vật nuôi',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: animalStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Đã xảy ra lỗi',
                style: TextStyle(color: Colors.red[700]),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            );
          }

          final animalData = snapshot.data?.data() as Map<String, dynamic>?;

          if (animalData == null) {
            return const Center(
              child: Text('Không tìm thấy thông tin vật nuôi'),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(
                  'Thông tin cơ bản',
                  [
                    _buildInfoField(
                      'Tên',
                      animalData['name'],
                      () => _showEditDialog(
                        'Tên',
                        animalData['name'],
                        (newValue) => FirebaseFirestore.instance
                            .collection('farm_animals')
                            .doc(widget.animalId)
                            .update({'name': newValue}),
                      ),
                    ),
                    _buildInfoField(
                      'Mã',
                      widget.animalId,
                      () {},
                    ),
                    _buildInfoField(
                      'Ngày sinh',
                      animalData['birthDate'],
                      () => _showEditDialog(
                        'Ngày sinh',
                        animalData['birthDate'],
                        (newValue) => FirebaseFirestore.instance
                            .collection('farm_animals')
                            .doc(widget.animalId)
                            .update({'birthDate': newValue}),
                      ),
                    ),
                    _buildInfoField(
                      'Tuổi',
                      _calculateAge(animalData['birthDate']),
                      () {},
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildInfoCard(
                  'Lịch sử khám bệnh',
                  [
                    _buildMedicalHistoryList(),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm lịch sử khám'),
                        onPressed: _showAddMedicalHistoryDialog,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}