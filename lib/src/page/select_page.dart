import 'package:flutter/material.dart';
import 'package:pi_farm/src/page/home/home_page.dart';
import 'package:pi_farm/src/page/settings/settings_page.dart';
import 'package:pi_farm/src/page/tasks/tasks_page.dart';
import 'package:pi_farm/src/page/cages/cages_page.dart'; // Add this import

class SelectPage extends StatefulWidget {
  const SelectPage({super.key});

  @override
  SelectPageState createState() => SelectPageState();
}

class SelectPageState extends State<SelectPage> {
  int currentindex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = [
      const HomePage(),
      const CagesPage(), // Replace Placeholder with CagesPage
      const TasksPage(),
      const SettingsPage(),
    ];
    return Scaffold(
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: Container(
            color: Colors.white,
            key: ValueKey<int>(currentindex),
            child: pages[currentindex],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
            onTap: (int index) {
              setState(() {
                currentindex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            currentIndex: currentindex,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.grid_view), label: 'Cages'), // Update icon and label
              BottomNavigationBarItem(
                  icon: Icon(Icons.event_note), label: 'Tasks'),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: "Settings",
              ),
            ]));
  }
}