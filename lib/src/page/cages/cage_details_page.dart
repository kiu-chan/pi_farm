import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pi_farm/src/page/cages/animal_details_page.dart';

class CageDetailsPage extends StatefulWidget {
  final String cageId;
  final String cageName;

  const CageDetailsPage(
      {Key? key, required this.cageId, required this.cageName})
      : super(key: key);

  @override
  _CageDetailsPageState createState() => _CageDetailsPageState();
}

class _CageDetailsPageState extends State<CageDetailsPage> {
  late Stream<QuerySnapshot> animalsStream;

  @override
  void initState() {
    super.initState();
    animalsStream = FirebaseFirestore.instance
        .collection('farm_animals')
        .where('cage_id', isEqualTo: widget.cageId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Động vật trong ${widget.cageName}'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: animalsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Đã có lỗi xảy ra'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final animals = snapshot.data?.docs ?? [];

          return ListView.builder(
            itemCount: animals.length,
            itemBuilder: (context, index) {
              final animal = animals[index];
              return ListTile(
                title: Text(animal['name']),
                subtitle: Text(
                    'Mã: ${animal.id} - Ngày sinh: ${animal['birthDate']}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AnimalDetailsPage(animalId: animal.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAnimalDialog(context),
        child: Icon(Icons.add),
      ),
    );
  }

  void _showAddAnimalDialog(BuildContext context) {
    String name = '';
    DateTime? birthDate;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Thêm con vật mới'),
          content: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                TextField(
                  decoration: InputDecoration(hintText: "Tên con vật"),
                  onChanged: (value) {
                    name = value;
                  },
                ),
                TextButton(
                  child: Text(birthDate == null
                      ? "Chọn ngày sinh"
                      : "Ngày sinh: ${DateFormat('dd/MM/yyyy').format(birthDate!)}"),
                  onPressed: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: birthDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null && picked != birthDate) {
                      birthDate = picked;
                      (context as Element).markNeedsBuild();
                    }
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Thêm'),
              onPressed: () {
                if (name.isNotEmpty && birthDate != null) {
                  _addAnimal(context, name, birthDate!);
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

  void _addAnimal(BuildContext context, String name, DateTime birthDate) async {
    try {
      // Lấy số lượng vật nuôi hiện có trong chuồng
      QuerySnapshot animalSnapshot = await FirebaseFirestore.instance
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
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã thêm con vật mới thành công')),
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi thêm con vật: $e')),
      );
    }
  }
}
