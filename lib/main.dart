import 'package:flutter/material.dart';
import 'ui/hospital_ui.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();  // Initialize Flutter bindings
  runApp(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            HospitalUI hospitalUI = HospitalUI();
            hospitalUI.run();  // Note: This might need to be modified to return a Widget
            return const Center(
              child: Text('Hospital Management System'),
            );
          },
        ),
      ),
    ),
  );
}