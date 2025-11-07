import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

import '../domain/patient.dart';
import '../domain/enums.dart';

class PatientRepository {
  final List<Patient> _patients = [];
  late final File _dataFile;

  PatientRepository._();

  /// Factory to initialize and load data
  static Future<PatientRepository> create() async {
    final repo = PatientRepository._();

    // Use a simple directory for CLI (no Flutter dependencies)
    final dir = Directory.current;
    repo._dataFile = File(p.join(dir.path, 'patients_data.json'));

    await repo._loadFromFile();
    return repo;
  }

  /// Register a new patient and save
  Future<void> registerPatient(Patient patient) async {
    _patients.add(patient);
    await _saveToFile();
    print('💾 Patient "${patient.name}" registered successfully!');
  }

  /// Find a patient by ID (null-safe)
  Patient? findPatientById(String id) {
    try {
      return _patients.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get all patients
  List<Patient> getAllPatients() => List.unmodifiable(_patients);

  /// Filter patients by priority
  List<Patient> getPatientsByPriority(PriorityLevel priority) {
    return _patients.where((p) => p.priority == priority).toList();
  }

  /// Save to local JSON file
  Future<void> _saveToFile() async {
    try {
      final data = {'patients': _patients.map((p) => p.toJson()).toList()};
      await _dataFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(data),
      );
    } catch (e) {
      print('❌ Error saving patient data to ${_dataFile.path}: $e');
    }
  }

  /// Load from local JSON file
  Future<void> _loadFromFile() async {
    try {
      if (!await _dataFile.exists()) return;

      final content = await _dataFile.readAsString();
      if (content.trim().isEmpty) return;

      final Map<String, dynamic> data = json.decode(content);
      final List<dynamic>? patientList = data['patients'] as List<dynamic>?;

      _patients.clear();
      if (patientList != null) {
        _patients.addAll(
          patientList.map(
            (e) => Patient.fromJson(Map<String, dynamic>.from(e)),
          ),
        );
      }

      print('📁 Loaded ${_patients.length} patients from ${_dataFile.path}');
    } catch (e) {
      print('❌ Error loading patient data from ${_dataFile.path}: $e');
    }
  }
}
