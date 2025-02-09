import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pi_farm/src/page/cages/cage_details_page.dart';

class CagesPage extends StatefulWidget {
  const CagesPage({Key? key}) : super(key: key);

  @override
  _CagesPageState createState() => _CagesPageState();
}

class _CagesPageState extends State<CagesPage> {
  late Stream<QuerySnapshot> cagesStream;
  
  // Định nghĩa các màu chủ đạo
  static const primaryColor = Color(0xFF64B5F6); // Xanh dương nhạt
  static const backgroundColor = Color(0xFFE3F2FD); // Nền xanh nhạt hơn
  static const accentColor = Color(0xFF1976D2); // Xanh đậm cho nhấn mạnh

  @override
  void initState() {
    super.initState();
    cagesStream = FirebaseFirestore.instance.collection('cages').snapshots();
  }

  void _showAddCageDialog() {
    String name = '';
    String code = '';
    String latitude = '';
    String longitude = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Thêm chuồng mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Tên chuồng',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) => name = value,
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Mã chuồng',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    helperText: 'Chỉ cho phép chữ in hoa và số',
                  ),
                  onChanged: (value) => code = value.toUpperCase(),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Vĩ độ',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) => latitude = value,
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Kinh độ',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) => longitude = value,
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
              child: const Text('Lưu'),
              onPressed: () {
                if (name.isNotEmpty &&
                    code.isNotEmpty &&
                    latitude.isNotEmpty &&
                    longitude.isNotEmpty) {
                  if (_isValidCageCode(code)) {
                    double? lat = double.tryParse(latitude);
                    double? lon = double.tryParse(longitude);
                    if (lat != null && lon != null) {
                      _addCage(name, code, GeoPoint(lat, lon));
                      Navigator.of(context).pop();
                    } else {
                      _showErrorSnackBar('Vĩ độ và kinh độ phải là số hợp lệ');
                    }
                  } else {
                    _showErrorSnackBar(
                        'Mã chuồng chỉ được phép viết in hoa không dấu và viết liền');
                  }
                } else {
                  _showErrorSnackBar('Vui lòng điền đầy đủ thông tin');
                }
              },
            ),
          ],
        );
      },
    );
  }

  bool _isValidCageCode(String code) {
    return RegExp(r'^[A-Z0-9]+$').hasMatch(code);
  }

  void _addCage(String name, String code, GeoPoint location) {
    FirebaseFirestore.instance.collection('cages').doc(code).set({
      'name': name,
      'location': location,
    }).then((_) {
      _showSuccessSnackBar('Đã thêm chuồng mới');
    }).catchError((error) {
      _showErrorSnackBar('Lỗi khi thêm chuồng: $error');
    });
  }

  void _showEditCageDialog(String cageId, String currentName, GeoPoint currentLocation) {
    String newName = currentName;
    String newLatitude = currentLocation.latitude.toString();
    String newLongitude = currentLocation.longitude.toString();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Chỉnh sửa thông tin chuồng'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Tên chuồng',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  controller: TextEditingController(text: currentName),
                  onChanged: (value) => newName = value,
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Vĩ độ',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  controller: TextEditingController(text: newLatitude),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) => newLatitude = value,
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Kinh độ',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  controller: TextEditingController(text: newLongitude),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) => newLongitude = value,
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
              child: const Text('Lưu'),
              onPressed: () {
                if (newName.isNotEmpty &&
                    newLatitude.isNotEmpty &&
                    newLongitude.isNotEmpty) {
                  double? lat = double.tryParse(newLatitude);
                  double? lon = double.tryParse(newLongitude);
                  if (lat != null && lon != null) {
                    _updateCage(cageId, newName, GeoPoint(lat, lon));
                    Navigator.of(context).pop();
                  } else {
                    _showErrorSnackBar('Vĩ độ và kinh độ phải là số hợp lệ');
                  }
                } else {
                  _showErrorSnackBar('Vui lòng điền đầy đủ thông tin');
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _updateCage(String cageId, String newName, GeoPoint newLocation) {
    FirebaseFirestore.instance.collection('cages').doc(cageId).update({
      'name': newName,
      'location': newLocation,
    }).then((_) {
      _showSuccessSnackBar('Đã cập nhật thông tin chuồng');
    }).catchError((error) {
      _showErrorSnackBar('Lỗi khi cập nhật chuồng: $error');
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
          'Danh sách chuồng',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: cagesStream,
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

          final cages = snapshot.data?.docs ?? [];

          if (cages.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.grid_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có chuồng nào',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.0,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: cages.length,
              itemBuilder: (context, index) {
                final cage = cages[index];
                final GeoPoint location = cage['location'];
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CageDetailsPage(
                            cageId: cage.id,
                            cageName: cage['name'],
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(15),
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.grid_view,
                                  size: 32,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                cage['name'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: accentColor,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Mã: ${cage.id}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Vị trí: ${location.latitude.toStringAsFixed(6)},\n${location.longitude.toStringAsFixed(6)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            icon: const Icon(Icons.edit, color: accentColor),
                            onPressed: () => _showEditCageDialog(
                              cage.id,
                              cage['name'],
                              location,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: accentColor,
        onPressed: _showAddCageDialog,
        child: const Icon(Icons.add, color: Colors.white),
        elevation: 4,
      ),
    );
  }
}