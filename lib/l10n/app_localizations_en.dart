// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get themeVicky => 'Vicky\'s Theme';

  @override
  String get hello => 'Hello';

  @override
  String get manageSmartHome => 'let\'s manage your smart home.';

  @override
  String get addRoom => 'Add Room';

  @override
  String get addDevice => 'Add Device';

  @override
  String get roomName => 'Room Name';

  @override
  String get deviceName => 'Device Name';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get allRooms => 'All Rooms';

  @override
  String get noDevices => 'No devices yet';

  @override
  String get noRooms => 'No rooms created yet';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get logout => 'Logout';

  @override
  String get familyList => 'Family List';

  @override
  String get functions => 'Functions';

  @override
  String get changeName => 'Change Name';

  @override
  String get save => 'Save';

  @override
  String get enterNewName => 'Enter new name';

  @override
  String get createdAt => 'Created At';

  @override
  String get id => 'ID';

  @override
  String get email => 'Email';

  @override
  String get lastLogin => 'Last Login';

  @override
  String get airCondition => 'Air Condition';

  @override
  String get livingRoom => 'Living room';

  @override
  String get celsius => 'Celsius';

  @override
  String get mode => 'Mode';

  @override
  String get auto => 'Auto';

  @override
  String get cool => 'Cool';

  @override
  String get dry => 'Dry';

  @override
  String get fanSpeed => 'Fan speed';

  @override
  String get low => 'Low';

  @override
  String get mid => 'Mid';

  @override
  String get high => 'High';

  @override
  String get power => 'Power';

  @override
  String get editRoom => 'Edit Room';

  @override
  String get deleteRoom => 'Delete Room';

  @override
  String get confirmDelete => 'Confirm Delete';

  @override
  String get delete => 'Delete';

  @override
  String get temperature => 'Temperature';

  @override
  String get humidity => 'Humidity';

  @override
  String get on => 'On';

  @override
  String get off => 'Off';

  @override
  String get lastUpdated => 'Last Updated';

  @override
  String get rooms => 'Rooms';

  @override
  String get devices => 'Devices';

  @override
  String get recentlyUsed => 'Recently Used';

  @override
  String get error => 'Error';

  @override
  String get roomNotFound => 'Room not found';

  @override
  String confirmDeleteRoom(String name) {
    return 'Are you sure you want to delete room \"$name\"? This action cannot be undone and will remove all associated devices.';
  }

  @override
  String get bedroom => 'Bedroom';

  @override
  String get kitchen => 'Kitchen';

  @override
  String get bathroom => 'Bathroom';

  @override
  String get studyRoom => 'Study Room';

  @override
  String get diningRoom => 'Dining Room';
}
