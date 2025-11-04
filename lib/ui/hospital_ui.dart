import 'dart:io';
import '../data/patient_repository.dart';
import '../data/room_repository.dart';
import '../domain/patient.dart';
import '../domain/room.dart';
import '../domain/enums.dart';
import '../domain/bed.dart';

class HospitalUI {
  late final PatientRepository patientRepo;
  late final RoomRepository roomRepo;
  
  // Make run() async
  Future<void> run() async {
    // Initialize repositories asynchronously
    patientRepo = await PatientRepository.create();
    roomRepo = await RoomRepository.create();
    
    print('🏥 WELCOME TO HOSPITAL MANAGEMENT SYSTEM');
    
    while (true) {
      _showMainMenu();
      String choice = _getInput('Enter your choice: ');
      
      switch (choice) {
        case '1': await _registerPatient(); break;
        case '2': _listPatients(); break;
        case '3': _searchPatient(); break;
        case '4': await _addRoom(); break;
        case '5': _listRooms(); break;
        case '6': _assignPatientToBed(); break;
        case '7': _dischargePatient(); break;
        case '8': _viewAvailableBeds(); break;
        case '9': _viewPatientBedInfo(); break;
        case '10': _putRoomUnderMaintenance(); break;
        case '11': 
          print('Thank you for using Hospital Management System!');
          return;
        default:
          print('❌ Invalid choice. Please try again.');
      }
    }
  }
  
  void _showMainMenu() {
    print('\n=== HOSPITAL MANAGEMENT SYSTEM ===');
    print('1. Register New Patient');
    print('2. List All Patients');
    print('3. Search Patient');
    print('4. Add New Room');
    print('5. List All Rooms');
    print('6. Assign Patient to Bed');
    print('7. Discharge Patient');
    print('8. View Available Beds');
    print('9. View Patient Bed Info');
    print('10. Put Room Under Maintenance');
    print('11. Exit');
  }
  
  Future<void> _registerPatient() async {
    print('\n--- PATIENT REGISTRATION ---');
    
    String id = _getInput('Enter patient ID: ');
    if (patientRepo.findPatientById(id) != null) {
      print('❌ Patient ID already exists!');
      return;
    }
    
    String name = _getInput('Enter full name: ');
    String gender = _getInput('Enter gender: ');
    String email = _getInput('Enter email: ');
    int age = int.tryParse(_getInput('Enter age: ')) ?? 0;
    String phone = _getInput('Enter phone: ');
    String address = _getInput('Enter address: ');
    
    print('\nSelect Priority Level:');
    print('1. Critical (ICU only)');
    print('2. Serious (ICU or Ward)');
    print('3. Stable (General or Private)');
    String priorityChoice = _getInput('Enter choice (1-3): ');
    
    PriorityLevel priority;
    switch (priorityChoice) {
      case '1': priority = PriorityLevel.Critical; break;
      case '2': priority = PriorityLevel.Serious; break;
      case '3': priority = PriorityLevel.Stable; break;
      default: 
        print('Invalid choice! Using Stable.');
        priority = PriorityLevel.Stable;
    }
    
    Patient newPatient = Patient(
      id: id,
      name: name,
      gender: gender,
      email: email,
      age: age,
      phone: phone,
      address: address,
      priority: priority,
    );
    
    await patientRepo.registerPatient(newPatient);
    print('✅ Patient $name registered successfully!');
  }
  
  void _assignPatientToBed() {
    print('\n--- ASSIGN PATIENT TO BED ---');
    
    String patientId = _getInput('Enter patient ID: ');
    Patient? patient = patientRepo.findPatientById(patientId);
    
    if (patient == null) {
      print('❌ Patient not found!');
      return;
    }
    
    if (patient.assignedBed != null) {
      print('❌ Patient already assigned to bed ${patient.assignedBed!.bedId}');
      return;
    }
    
    bool success = roomRepo.assignPatientToBed(patient);
    
    if (success) {
      print('✅ Patient ${patient.name} assigned to bed ${patient.assignedBed!.bedId}');
      print('📍 Room type: ${_getRoomTypeForPriority(patient.priority)}');
    } else {
      print('❌ No suitable beds available for ${patient.priority.toString().split('.').last} priority patient');
    }
  }
  
  void _dischargePatient() {
    print('\n--- DISCHARGE PATIENT ---');
    
    String patientId = _getInput('Enter patient ID: ');
    Patient? patient = patientRepo.findPatientById(patientId);
    
    if (patient == null) {
      print('❌ Patient not found!');
      return;
    }
    
    if (patient.assignedBed == null) {
      print('❌ Patient is not assigned to any bed');
      return;
    }
    
    roomRepo.dischargePatient(patient);
    print('✅ Patient ${patient.name} discharged successfully!');
    print('🛏️ Bed ${patient.assignedBed?.bedId} is now available');
  }
  
  void _listPatients() {
    var patients = patientRepo.getAllPatients();
    if (patients.isEmpty) {
      print('No patients registered.');
      return;
    }
    
    print('\n--- REGISTERED PATIENTS (${patients.length}) ---');
    for (var patient in patients) {
      String bedInfo = patient.assignedBed != null 
          ? 'Assigned to: ${patient.assignedBed!.bedId}'
          : 'No bed assigned';
      print('${patient.id} - ${patient.name} (${patient.priority.toString().split('.').last}) - $bedInfo');
    }
  }
  
  void _searchPatient() {
    print('\n--- SEARCH PATIENT ---');
    
    String searchTerm = _getInput('Enter patient ID or name: ');
    var patients = patientRepo.getAllPatients();
    
    var results = patients.where((patient) =>
      patient.id.toLowerCase().contains(searchTerm.toLowerCase()) ||
      patient.name.toLowerCase().contains(searchTerm.toLowerCase())
    ).toList();
    
    if (results.isEmpty) {
      print('❌ No patients found matching "$searchTerm"');
      return;
    }
    
    print('\n--- SEARCH RESULTS (${results.length}) ---');
    for (var patient in results) {
      String bedInfo = patient.assignedBed != null 
          ? 'Assigned to: ${patient.assignedBed!.bedId}'
          : 'No bed assigned';
      print('${patient.id} - ${patient.name} (${patient.priority.toString().split('.').last}) - $bedInfo');
    }
  }
  
  Future<void> _addRoom() async {
    print('\n--- ADD NEW ROOM ---');
    
    String roomNumber = _getInput('Enter room number: ');
    if (roomRepo.findRoomByNumber(roomNumber) != null) {
      print('❌ Room $roomNumber already exists!');
      return;
    }
    
    print('Select room type:');
    print('1. ICU (Critical patients only)');
    print('2. Ward (Serious patients)');
    print('3. General (Stable patients)');
    print('4. Private (Stable patients)');
    String typeChoice = _getInput('Enter choice (1-4): ');
    
    RoomType type;
    switch (typeChoice) {
      case '1': type = RoomType.ICU; break;
      case '2': type = RoomType.Ward; break;
      case '3': type = RoomType.General; break;
      case '4': type = RoomType.Private; break;
      default: 
        print('Invalid choice! Using General.');
        type = RoomType.General;
    }
    
    int capacity = int.tryParse(_getInput('Enter room capacity (number of beds): ')) ?? 1;
    
    Room newRoom = Room(roomNumber: roomNumber, type: type, capacity: capacity);
    roomRepo.addRoom(newRoom);
    
    print('\n✅ Room $roomNumber (${type.toString().split('.').last}) created successfully!');
    print('✅ $capacity bed(s) automatically created');
  }
  
  void _listRooms() {
    var rooms = roomRepo.getAllRooms();
    if (rooms.isEmpty) {
      print('No rooms available.');
      return;
    }
    
    print('\n--- AVAILABLE ROOMS (${rooms.length}) ---');
    for (var room in rooms) {
      String maintenanceStatus = room.isUnderMaintenance ? '🚧 UNDER MAINTENANCE' : '✅ OPERATIONAL';
      print('${room.roomNumber} - ${room.type.toString().split('.').last} - Beds: ${room.getAvailableBeds().length}/${room.capacity} available - $maintenanceStatus');
    }
  }
  
  void _viewAvailableBeds() {
    print('\n--- AVAILABLE Beds ---');
    
    var availableBeds = roomRepo.getAllAvailableBeds();
    if (availableBeds.isEmpty) {
      print('❌ No available beds at the moment.');
      return;
    }
    
    // Group by room
    Map<String, List<Bed>> bedsByRoom = {};
    for (var bed in availableBeds) {
      if (!bedsByRoom.containsKey(bed.roomNumber)) {
        bedsByRoom[bed.roomNumber] = [];
      }
      bedsByRoom[bed.roomNumber]!.add(bed);
    }
    
    for (var roomNumber in bedsByRoom.keys) {
      var room = roomRepo.findRoomByNumber(roomNumber);
      print('\nRoom $roomNumber (${room?.type.toString().split('.').last}):');
      for (var bed in bedsByRoom[roomNumber]!) {
        print('  - ${bed.bedId}');
      }
    }
  }
  
  void _viewPatientBedInfo() {
    print('\n--- PATIENT BED INFORMATION ---');
    
    String patientId = _getInput('Enter patient ID: ');
    Patient? patient = patientRepo.findPatientById(patientId);
    
    if (patient == null) {
      print('❌ Patient not found!');
      return;
    }
    
    print('\n--- PATIENT DETAILS ---');
    print('ID: ${patient.id}');
    print('Name: ${patient.name}');
    print('Priority: ${patient.priority.toString().split('.').last}');
    print('Age: ${patient.age}');
    print('Phone: ${patient.phone}');
    
    if (patient.assignedBed != null) {
      var room = roomRepo.findRoomByNumber(patient.assignedBed!.roomNumber);
      print('\n--- BED ASSIGNMENT ---');
      print('Bed: ${patient.assignedBed!.bedId}');
      print('Room: ${patient.assignedBed!.roomNumber} (${room?.type.toString().split('.').last})');
      print('Room Status: ${room?.isUnderMaintenance == true ? "🚧 Under Maintenance" : "✅ Operational"}');
    } else {
      print('\n--- BED ASSIGNMENT ---');
      print('❌ No bed assigned');
      print('Suggested room type: ${_getRoomTypeForPriority(patient.priority)}');
    }
  }
  
  void _putRoomUnderMaintenance() {
    print('\n--- ROOM MAINTENANCE ---');
    
    String roomNumber = _getInput('Enter room number to put under maintenance: ');
    var room = roomRepo.findRoomByNumber(roomNumber);
    
    if (room == null) {
      print('❌ Room not found!');
      return;
    }
    
    if (room.isUnderMaintenance) {
      print('❌ Room is already under maintenance');
      return;
    }
    
    // Check if room has occupied beds
    var occupiedBeds = room.beds.where((bed) => !bed.isAvailable()).toList();
    if (occupiedBeds.isNotEmpty) {
      print('❌ Cannot put room under maintenance - it has ${occupiedBeds.length} occupied bed(s)');
      print('Please discharge patients first:');
      for (var bed in occupiedBeds) {
        print('  - ${bed.bedId} occupied by patient ${bed.patientId}');
      }
      return;
    }
    
    roomRepo.updateRoomMaintenance(roomNumber, true);
    print('✅ Room $roomNumber is now under maintenance 🚧');
  }
  
  String _getRoomTypeForPriority(PriorityLevel priority) {
    switch (priority) {
      case PriorityLevel.Critical: return 'ICU';
      case PriorityLevel.Serious: return 'ICU or Ward';
      case PriorityLevel.Stable: return 'General or Private';
      default: return 'Unknown';
    }
  }
  
  String _getInput(String prompt) {
    stdout.write(prompt);
    return stdin.readLineSync()?.trim() ?? '';
  }
}