// This file defines the data models used in the application, including User, Attendance, AppTransaction, Goal, Loan, DriverTrip, TrafficFine, DocumentItem, and NoteItem. Each class includes properties relevant to its entity and methods for JSON serialization and deserialization.
class User {
  int? id;
  String name;
  String passwordHash;
  double fixedSalary;
  double dutyRatePerHour;
  double otRatePerHour;
  bool isHeavyVehicleDriver;
  double tripRate;
  int createdAt;
  DateTime? joiningDate;

  User({
    this.id,
    required this.name,
    required this.passwordHash,
    this.fixedSalary = 1500.0,
    this.dutyRatePerHour = 5.0,
    this.otRatePerHour = 5.0,
    this.isHeavyVehicleDriver = false,
    this.tripRate = 0.0,
    this.joiningDate,
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'passwordHash': passwordHash,
        'fixedSalary': fixedSalary,
        'dutyRatePerHour': dutyRatePerHour,
        'otRatePerHour': otRatePerHour,
        'createdAt': createdAt,
        'isHeavyVehicleDriver': isHeavyVehicleDriver,
        'tripRate': tripRate,
        'joiningDate': joiningDate?.toIso8601String(),
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        name: json['name'],
        passwordHash: json['passwordHash'],
        fixedSalary: (json['fixedSalary'] as num?)?.toDouble() ?? 1500.0,
        dutyRatePerHour: (json['dutyRatePerHour'] as num?)?.toDouble() ?? 5.0,
        otRatePerHour: (json['otRatePerHour'] as num?)?.toDouble() ?? 5.0,
        isHeavyVehicleDriver: json['isHeavyVehicleDriver'] ?? false,
        tripRate: (json['tripRate'] as num?)?.toDouble() ?? 0.0,
        joiningDate: json['joiningDate'] != null
            ? DateTime.parse(json['joiningDate'])
            : null,
        createdAt: json['createdAt'],
      );
}

class Attendance {
  int? id;
  DateTime date;
  DateTime? dutyStart;
  DateTime? dutyEnd;
  double dutyHours;
  DateTime? otStart;
  DateTime? otEnd;
  double otHours;
  int trips;
  String status;
  String? notes;

  Attendance({
    this.id,
    required this.date,
    this.dutyStart,
    this.dutyEnd,
    this.dutyHours = 0.0,
    this.otStart,
    this.otEnd,
    this.otHours = 0.0,
    this.trips = 0,
    required this.status,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'dutyStart': dutyStart?.toIso8601String(),
        'dutyEnd': dutyEnd?.toIso8601String(),
        'dutyHours': dutyHours,
        'otStart': otStart?.toIso8601String(),
        'otEnd': otEnd?.toIso8601String(),
        'otHours': otHours,
        'trips': trips,
        'status': status,
        'notes': notes,
      };

  factory Attendance.fromJson(Map<String, dynamic> json) => Attendance(
        id: json['id'],
        date: DateTime.parse(json['date']),
        dutyStart: json['dutyStart'] != null
            ? DateTime.parse(json['dutyStart'])
            : null,
        dutyEnd:
            json['dutyEnd'] != null ? DateTime.parse(json['dutyEnd']) : null,
        dutyHours: (json['dutyHours'] as num?)?.toDouble() ?? 0.0,
        otStart:
            json['otStart'] != null ? DateTime.parse(json['otStart']) : null,
        otEnd: json['otEnd'] != null ? DateTime.parse(json['otEnd']) : null,
        otHours: (json['otHours'] as num?)?.toDouble() ?? 0.0,
        trips: json['trips'] ?? 0,
        status: json['status'],
        notes: json['notes'],
      );
}

class AppTransaction {
  int? id;
  String type;
  double amount;
  String currency;
  String category;
  String? description;
  DateTime date;
  double? exchangeRate;
  double? inrReceived;
  String? notes;

  AppTransaction({
    this.id,
    required this.type,
    required this.amount,
    required this.currency,
    required this.category,
    this.description,
    required this.date,
    this.exchangeRate,
    this.inrReceived,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'amount': amount,
        'currency': currency,
        'category': category,
        'description': description,
        'date': date.toIso8601String(),
        'exchangeRate': exchangeRate,
        'inrReceived': inrReceived,
        'notes': notes,
      };

  factory AppTransaction.fromJson(Map<String, dynamic> json) => AppTransaction(
        id: json['id'],
        type: json['type'],
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        currency: json['currency'],
        category: json['category'],
        description: json['description'],
        date: DateTime.parse(json['date']),
        exchangeRate: (json['exchangeRate'] as num?)?.toDouble(),
        inrReceived: (json['inrReceived'] as num?)?.toDouble(),
        notes: json['notes'],
      );
}

class Goal {
  int? id;
  String type;
  String title;
  double targetAmount;
  double currentAmount;
  DateTime deadline;

  Goal({
    this.id,
    required this.type,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.deadline,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'deadline': deadline.toIso8601String(),
      };

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
        id: json['id'],
        type: json['type'],
        title: json['title'],
        targetAmount: (json['targetAmount'] as num?)?.toDouble() ?? 0.0,
        currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0.0,
        deadline: DateTime.parse(json['deadline']),
      );
}

class Loan {
  int? id;
  String person;
  double amount;
  String currency;
  DateTime date;
  DateTime? dueDate;
  String status;
  String type;
  String? notes;

  Loan({
    this.id,
    required this.person,
    required this.amount,
    required this.currency,
    required this.date,
    this.dueDate,
    required this.status,
    required this.type,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'person': person,
        'amount': amount,
        'currency': currency,
        'date': date.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'status': status,
        'type': type,
        'notes': notes,
      };

  factory Loan.fromJson(Map<String, dynamic> json) => Loan(
        id: json['id'],
        person: json['person'],
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        currency: json['currency'],
        date: DateTime.parse(json['date']),
        dueDate:
            json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
        status: json['status'],
        type: json['type'],
        notes: json['notes'],
      );
}

class DriverTrip {
  int? id;
  String destination;
  double allowance;
  DateTime date;
  String? notes;
  String? vehicleNumber;
  double? fuelProvided;
  double? cargoTonnage;
  String? clientName;

  DriverTrip({
    this.id,
    required this.destination,
    required this.allowance,
    required this.date,
    this.notes,
    this.vehicleNumber,
    this.fuelProvided,
    this.cargoTonnage,
    this.clientName,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'destination': destination,
        'allowance': allowance,
        'date': date.toIso8601String(),
        'notes': notes,
        'vehicleNumber': vehicleNumber,
        'fuelProvided': fuelProvided,
        'cargoTonnage': cargoTonnage,
        'clientName': clientName,
      };

  factory DriverTrip.fromJson(Map<String, dynamic> json) => DriverTrip(
        id: json['id'],
        destination: json['destination'],
        allowance: (json['allowance'] as num?)?.toDouble() ?? 0.0,
        date: DateTime.parse(json['date']),
        notes: json['notes'],
        vehicleNumber: json['vehicleNumber'],
        fuelProvided: (json['fuelProvided'] as num?)?.toDouble(),
        cargoTonnage: (json['cargoTonnage'] as num?)?.toDouble(),
        clientName: json['clientName'],
      );
}

class TrafficFine {
  int? id;
  int? tripId;
  double amount;
  DateTime date;
  String location;
  String description;
  String status; // e.g. "Unpaid", "Paid"

  TrafficFine({
    this.id,
    this.tripId,
    required this.amount,
    required this.date,
    required this.location,
    required this.description,
    this.status = 'Unpaid',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'tripId': tripId,
        'amount': amount,
        'date': date.toIso8601String(),
        'location': location,
        'description': description,
        'status': status,
      };

  factory TrafficFine.fromJson(Map<String, dynamic> json) => TrafficFine(
        id: json['id'],
        tripId: json['tripId'],
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        date: DateTime.parse(json['date']),
        location: json['location'],
        description: json['description'],
        status: json['status'] ?? 'Unpaid',
      );
}

class DocumentItem {
  int? id;
  String title;
  String category;
  DateTime? expiryDate;
  String? notes;

  DocumentItem({
    this.id,
    required this.title,
    required this.category,
    this.expiryDate,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'expiryDate': expiryDate?.toIso8601String(),
        'notes': notes,
      };

  factory DocumentItem.fromJson(Map<String, dynamic> json) => DocumentItem(
        id: json['id'],
        title: json['title'],
        category: json['category'],
        expiryDate: json['expiryDate'] != null
            ? DateTime.parse(json['expiryDate'])
            : null,
        notes: json['notes'],
      );
}

class NoteItem {
  int? id;
  String title;
  String content;
  String type;
  int createdAt;

  NoteItem({
    this.id,
    required this.title,
    required this.content,
    required this.type,
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'type': type,
        'createdAt': createdAt,
      };

  factory NoteItem.fromJson(Map<String, dynamic> json) => NoteItem(
        id: json['id'],
        title: json['title'],
        content: json['content'],
        type: json['type'],
        createdAt: json['createdAt'],
      );
}
