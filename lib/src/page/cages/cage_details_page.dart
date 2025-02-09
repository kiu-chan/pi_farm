import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pi_farm/src/page/cages/animal_details_page.dart';

class CageDetailsPage extends StatefulWidget {
  final String cageId;
  final String cageName;

  const CageDetailsPage({
    Key? key,
    required this.cageId,
    required this.cageName,
  }) : super(key: key);

  @override
  _CageDetailsPageState createState() => _CageDetailsPageState();
}

class _CageDetailsPageState extends State<CageDetailsPage> {
  late Stream<QuerySnapshot> animalsStream;

  // Định nghĩa các màu chủ đạo
  static const primaryColor = Color(0xFF64B5F6); // Xanh dương nhạt
  static const backgroundColor = Color(0xFFE3F2FD); // Nền xanh nhạt hơn
  static const accentColor = Color(0xFF1976D2); // Xanh đậm cho nhấn mạnh

  @override
  void initState() {
    super.initState();
    animalsStream = FirebaseFirestore.instance
        .collection('farm_animals')
        .where('cage_id', isEqualTo: widget.cageId)
        .snapshots();
  }

  String _calculateAge(String birthDateString) {
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
      return 'Không xác định';
    }
  }

  void _showAddAnimalDialog() {
    String name = '';
    DateTime? birthDate;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Thêm vật nuôi mới'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Tên vật nuôi',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) => name = value,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          birthDate == null
                              ? 'Chọn ngày sinh'
                              : 'Ngày sinh: ${DateFormat('dd/MM/yyyy').format(birthDate!)}',
                        ),
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: birthDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: primaryColor,
                                    onPrimary: Colors.white,
                                    surface: Colors.white,
                                    onSurface: Colors.black,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null && picked != birthDate) {
                            setState(() => birthDate = picked);
                          }
                        },
                      ),
                    ),
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
                  child: const Text('Thêm'),
                  onPressed: () {
                    if (name.isNotEmpty && birthDate != null) {
                      _addAnimal(name, birthDate!);
                      Navigator.of(context).pop();
                    } else {
                      _showErrorSnackBar('Vui lòng điền đầy đủ thông tin');
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addAnimal(String name, DateTime birthDate) async {
    try {
      final QuerySnapshot animalSnapshot = await FirebaseFirestore.instance
          .collection('farm_animals')
          .where('cage_id', isEqualTo: widget.cageId)
          .get();

      int animalCount = animalSnapshot.docs.length + 1;
      String animalCode = '${widget.cageId}_$animalCount';

      await FirebaseFirestore.instance
          .collection('farm_animals')
          .doc(animalCode)
          .set({
        'name': name,
        'birthDate': DateFormat('dd/MM/yyyy').format(birthDate),
        'cage_id': widget.cageId,
      });

      _showSuccessSnackBar('Đã thêm vật nuôi mới thành công');
    } catch (e) {
      _showErrorSnackBar('Lỗi khi thêm vật nuôi: $e');
    }
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
        title: Text(
          'Chuồng ${widget.cageName}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: animalsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Đã có lỗi xảy ra',
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

          final animals = snapshot.data?.docs ?? [];

          if (animals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pets,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có vật nuôi nào trong chuồng',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: animals.length,
            itemBuilder: (context, index) {
              final animal = animals[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.pets,
                      color: primaryColor,
                    ),
                  ),
                  title: Text(
                    animal['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Mã: ${animal.id}'),
                      Text(
                        'Tuổi: ${_calculateAge(animal['birthDate'])}',
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AnimalDetailsPage(animalId: animal.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: accentColor,
        onPressed: _showAddAnimalDialog,
        child: const Icon(Icons.add, color: Colors.white),
        elevation: 4,
      ),
    );
  }
}