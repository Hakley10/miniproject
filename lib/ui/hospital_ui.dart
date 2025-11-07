import 'dart:io';
import '../data/patient_repository.dart';
import '../data/room_repository.dart';
import '../domain/patient.dart';
import '../domain/enums.dart';
import '../domain/hospital_service.dart';
import '../domain/room.dart';

class HospitalUI {
  late final HospitalService hospitalService;

  Future<void> run() async {
    final patientRepo = await PatientRepository.create();
    final roomRepo = await RoomRepository.create();
    hospitalService = HospitalService(patientRepo, roomRepo);

    print('🏥 WELCOME TO HOSPITAL MANAGEMENT SYSTEM');

    while (true) {
      // ✅ Clear console before showing menu
      stdout.write('\x1B[2J\x1B[0;0H');

      _showMainMenu();
      String choice = _getInput('Enter your choice: ');

      switch (choice) {
        case '1':
          await _registerPatient();
          break;
        case '2':
          _listPatients();
          break;
        case '3':
          _searchPatient();
          break;
        case '4':
          _addRoom();
          break;
        case '5':
          _listRooms();
          break;
        case '6':
          await _assignPatientToBed();
          break;
        case '7':
          _dischargePatient();
          break;
        case '8':
          _viewPatientBedInfo();
          break;
        case '9':
          print('👋 Thank you for using Hospital Management System!');
          return;
        default:
          print('❌ Invalid choice.');
      }

      // ✅ Pause before redisplaying the main menu
      _getInput('\nPress Enter to continue...');
    }
  }

  void _showMainMenu() {
    print('''
=== HOSPITAL MANAGEMENT SYSTEM ===
1. Register Patient
2. List Patients
3. Search Patient
4. Add Room
5. List Rooms
6. Assign Patient to Bed
7. Discharge Patient
8. View Patient Bed Info
9. Exit
''');
  }

  Future<void> _registerPatient() async {
    print('--- PATIENT REGISTRATION ---');

    String id = _getInput('Enter patient ID: ');
    final existing = hospitalService.getAllPatients().any((p) => p.id == id);
    if (existing) {
      print('❌ Patient ID "$id" already exists!');
      return;
    }

    String name = _getInput('Enter name: ');
    String gender = _getInput('Enter gender: ');
    String email = _getInput('Enter email: ');
    int age = int.tryParse(_getInput('Enter age: ')) ?? 0;
    String phone = _getInput('Enter phone: ');
    String address = _getInput('Enter address: ');

    print('\n1. Critical  2. Serious  3. Stable');
    String priorityInput = _getInput('Priority: ');
    PriorityLevel priority;
    switch (priorityInput) {
      case '1':
        priority = PriorityLevel.critical;
        break;
      case '2':
        priority = PriorityLevel.serious;
        break;
      default:
        priority = PriorityLevel.stable;
    }

    final patient = Patient(
      id: id,
      name: name,
      gender: gender,
      email: email,
      age: age,
      phone: phone,
      address: address,
      priority: priority,
    );

    final message = await hospitalService.registerPatient(patient);
    print(message);
  }

  Future<void> _assignPatientToBed() async{
    print('\n--- ASSIGN PATIENT ---');
    String id = _getInput('Patient ID: ');
    print(await hospitalService.assignPatientToBed(id));
  }

  void _dischargePatient() {
    print('\n--- DISCHARGE ---');
    String id = _getInput('Patient ID: ');
    print(hospitalService.dischargePatient(id));
  }

  void _addRoom() {
    print('\n--- ADD ROOM ---');
    String roomNumber = _getInput('Room Number: ');
    print('1. ICU  2. Ward  3. General  4. Private');
    String choice = _getInput('Type: ');
    RoomType type = switch (choice) {
      '1' => RoomType.icu,
      '2' => RoomType.ward,
      '3' => RoomType.general,
      '4' => RoomType.private,
      _ => RoomType.general,
    };
    int capacity = int.tryParse(_getInput('Capacity: ')) ?? 1;
    print(hospitalService.addRoom(roomNumber, type, capacity));
  }

  void _listPatients() {
    final list = hospitalService.getAllPatients();
    if (list.isEmpty) {
      print('No patients.');
      return;
    }
    print('\n--- PATIENT LIST ---');
    for (var p in list) {
      print('${p.id} - ${p.name} (${p.priority.name})');
    }
  }

  void _searchPatient() {
    String term = _getInput('Search term: ');
    final results = hospitalService
        .getAllPatients()
        .where((p) =>
            p.name.toLowerCase().contains(term.toLowerCase()) ||
            p.id.toLowerCase().contains(term.toLowerCase()))
        .toList();

    if (results.isEmpty) {
      print('No results.');
    } else {
      print('\n--- SEARCH RESULTS ---');
      for (var p in results) {
        print('${p.id} - ${p.name}');
      }
    }
  }

  void _listRooms() {
    final rooms = hospitalService.getAllRooms();
    if (rooms.isEmpty) {
      print('No rooms.');
      return;
    }
    print('\n--- ROOM LIST ---');
    for (var r in rooms) {
      print('${r.roomNumber} (${r.type.name}) - ${r.capacity} beds');
    }
  }

  void _viewPatientBedInfo() {
    print('\n--- PATIENT BED INFO ---');
    String id = _getInput('Patient ID: ');
    print(hospitalService.viewPatientBedInfo(id));
  }

  String _getInput(String prompt) {
    stdout.write(prompt);
    return stdin.readLineSync()?.trim() ?? '';
  }
}
