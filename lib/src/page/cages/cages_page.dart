import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pi_farm/src/page/cages/cage_details_page.dart';
import 'animal_details_page.dart';

class CagesPage extends StatefulWidget {
  const CagesPage({Key? key}) : super(key: key);

  @override
  _CagesPageState createState() => _CagesPageState();
}

class _CagesPageState extends State<CagesPage> {
  late Stream<QuerySnapshot> cagesStream;

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
          title: Text('Thêm chuồng mới'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(labelText: 'Tên chuồng'),
                  onChanged: (value) => name = value,
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Mã chuồng'),
                  onChanged: (value) => code = value.toUpperCase(),
                  textCapitalization: TextCapitalization.characters,
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Vĩ độ'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) => latitude = value,
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Kinh độ'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) => longitude = value,
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('Vĩ độ và kinh độ phải là số hợp lệ')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Mã chuồng chỉ được phép viết in hoa không dấu và viết liền')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
                  );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã thêm chuồng mới')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi thêm chuồng: $error')),
      );
    });
  }

  void _showEditCageDialog(
      String cageId, String currentName, GeoPoint currentLocation) {
    String newName = currentName;
    String newLatitude = currentLocation.latitude.toString();
    String newLongitude = currentLocation.longitude.toString();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Chỉnh sửa thông tin chuồng'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(labelText: 'Tên chuồng'),
                  controller: TextEditingController(text: currentName),
                  onChanged: (value) => newName = value,
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Vĩ độ'),
                  controller: TextEditingController(text: newLatitude),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) => newLatitude = value,
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Kinh độ'),
                  controller: TextEditingController(text: newLongitude),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) => newLongitude = value,
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
                if (newName.isNotEmpty &&
                    newLatitude.isNotEmpty &&
                    newLongitude.isNotEmpty) {
                  double? lat = double.tryParse(newLatitude);
                  double? lon = double.tryParse(newLongitude);
                  if (lat != null && lon != null) {
                    _updateCage(cageId, newName, GeoPoint(lat, lon));
                    Navigator.of(context).pop();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Vĩ độ và kinh độ phải là số hợp lệ')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
                  );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã cập nhật thông tin chuồng')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi cập nhật chuồng: $error')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách chuồng'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: cagesStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Đã có lỗi xảy ra'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final cages = snapshot.data?.docs ?? [];

          return ListView.builder(
            itemCount: cages.length,
            itemBuilder: (context, index) {
              final cage = cages[index];
              final GeoPoint location = cage['location'];
              return ListTile(
                title: Text(cage['name']),
                subtitle: Text(
                    'Mã: ${cage.id} - Vị trí: ${location.latitude}, ${location.longitude}'),
                trailing: IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () =>
                      _showEditCageDialog(cage.id, cage['name'], location),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CageDetailsPage(
                          cageId: cage.id, cageName: cage['name']),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCageDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}
