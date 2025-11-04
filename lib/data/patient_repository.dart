import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../domain/patient.dart';
import '../domain/enums.dart'; 

class PatientRepository {
  final List<Patient> _patients = [];
  late final File _dataFile;

  PatientRepository._();

  // Use async factory to initialize file path and load data
  static Future<PatientRepository> create() async {
    final repo = PatientRepository._();
    final dir = await getApplicationDocumentsDirectory();
    repo._dataFile = File(p.join(dir.path, 'patients_data.json'));
    await repo._loadFromFile();
    return repo;
  }

  Future<void> registerPatient(Patient patient) async {
    _patients.add(patient);
    await _saveToFile();
    print('💾 Patient ${patient.name} registered and saved!');
  }

  // return nullable Patient safely
  Patient? findPatientById(String id) {
    for (final p in _patients) {
      if (p.id == id) return p;
    }
    return null;
  }

  List<Patient> getAllPatients() => List.from(_patients);

  // Keep this if PriorityLevel is defined in domain/patient.dart
  List<Patient> getPatientsByPriority(PriorityLevel priority) {
    return _patients.where((patient) => patient.priority == priority).toList();
  }

  Future<void> _saveToFile() async {
    try {
      final data = {
        'patients': _patients.map((p) => p.toJson()).toList(),
      };
      await _dataFile.writeAsString(json.encode(data));
    } catch (e) {
      print('❌ Error saving patient data: $e');
    }
  }

  Future<void> _loadFromFile() async {
    try {
      if (await _dataFile.exists()) {
        final content = await _dataFile.readAsString();
        if (content.trim().isEmpty) return;
        final Map<String, dynamic> data = json.decode(content);
        final patientsList = data['patients'] as List<dynamic>?;
        _patients.clear();
        if (patientsList != null) {
          for (var patientData in patientsList) {
            _patients.add(Patient.fromJson(Map<String, dynamic>.from(patientData)));
          }
        }
        print('📁 Loaded ${_patients.length} patients from storage');
      }
    } catch (e) {
      print('❌ Error loading patient data: $e');
    }
  }
}