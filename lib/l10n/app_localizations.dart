import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
    Locale('zh', 'CN'),
    Locale('zh', 'TW')
  ];

  /// The theme name for Vicky's theme
  ///
  /// In en, this message translates to:
  /// **'Vicky\'s Theme'**
  String get themeVicky;

  /// The theme name for Aurora theme
  ///
  /// In en, this message translates to:
  /// **'Aurora Theme'**
  String get themeAurora;

  /// Greeting text on the main page
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// Subtitle text on the main page
  ///
  /// In en, this message translates to:
  /// **'let\'s manage your smart home.'**
  String get manageSmartHome;

  /// Button to add a new room
  ///
  /// In en, this message translates to:
  /// **'Add Room'**
  String get addRoom;

  /// Button to add a new device
  ///
  /// In en, this message translates to:
  /// **'Add Device'**
  String get addDevice;

  /// Label for room name input
  ///
  /// In en, this message translates to:
  /// **'Room Name'**
  String get roomName;

  /// Label for device name input
  ///
  /// In en, this message translates to:
  /// **'Device Name'**
  String get deviceName;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Confirm button text
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Tab title for all rooms
  ///
  /// In en, this message translates to:
  /// **'All Rooms'**
  String get allRooms;

  /// Message when no devices are available
  ///
  /// In en, this message translates to:
  /// **'No devices yet'**
  String get noDevices;

  /// Message when no rooms are available
  ///
  /// In en, this message translates to:
  /// **'No rooms created yet'**
  String get noRooms;

  /// Profile page title
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Settings menu item
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Logout button text
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Title for the family members list
  ///
  /// In en, this message translates to:
  /// **'Family List'**
  String get familyList;

  /// Title for the functions section
  ///
  /// In en, this message translates to:
  /// **'Functions'**
  String get functions;

  /// Button to change user name
  ///
  /// In en, this message translates to:
  /// **'Change Name'**
  String get changeName;

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Placeholder for name input field
  ///
  /// In en, this message translates to:
  /// **'Enter new name'**
  String get enterNewName;

  /// Label for account creation date
  ///
  /// In en, this message translates to:
  /// **'Created At'**
  String get createdAt;

  /// Label for user ID
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get id;

  /// Label for user email
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Label for last login date
  ///
  /// In en, this message translates to:
  /// **'Last Login'**
  String get lastLogin;

  /// Title for air conditioner page
  ///
  /// In en, this message translates to:
  /// **'Air Condition'**
  String get airCondition;

  /// Living room label
  ///
  /// In en, this message translates to:
  /// **'Living room'**
  String get livingRoom;

  /// Temperature unit label
  ///
  /// In en, this message translates to:
  /// **'Celsius'**
  String get celsius;

  /// AC mode label
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get mode;

  /// AC auto mode
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get auto;

  /// AC cool mode
  ///
  /// In en, this message translates to:
  /// **'Cool'**
  String get cool;

  /// AC dry mode
  ///
  /// In en, this message translates to:
  /// **'Dry'**
  String get dry;

  /// Fan speed label
  ///
  /// In en, this message translates to:
  /// **'Fan speed'**
  String get fanSpeed;

  /// Low fan speed
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// Medium fan speed
  ///
  /// In en, this message translates to:
  /// **'Mid'**
  String get mid;

  /// High fan speed
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// Power label
  ///
  /// In en, this message translates to:
  /// **'Power'**
  String get power;

  /// Button to edit a room
  ///
  /// In en, this message translates to:
  /// **'Edit Room'**
  String get editRoom;

  /// Button to delete a room
  ///
  /// In en, this message translates to:
  /// **'Delete Room'**
  String get deleteRoom;

  /// Title for deletion confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDelete;

  /// Delete button text
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Temperature label
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// Humidity label
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get humidity;

  /// On state label
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get on;

  /// Off state label
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// Last updated label
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get lastUpdated;

  /// Rooms label
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get rooms;

  /// Devices label
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get devices;

  /// Recently used label
  ///
  /// In en, this message translates to:
  /// **'Recently Used'**
  String get recentlyUsed;

  /// Error message
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Message when a room cannot be found
  ///
  /// In en, this message translates to:
  /// **'Room not found'**
  String get roomNotFound;

  /// Confirmation message for room deletion
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete room \"{name}\"? This action cannot be undone and will remove all associated devices.'**
  String confirmDeleteRoom(String name);

  /// Bedroom label
  ///
  /// In en, this message translates to:
  /// **'Bedroom'**
  String get bedroom;

  /// Kitchen label
  ///
  /// In en, this message translates to:
  /// **'Kitchen'**
  String get kitchen;

  /// Bathroom label
  ///
  /// In en, this message translates to:
  /// **'Bathroom'**
  String get bathroom;

  /// Study room label
  ///
  /// In en, this message translates to:
  /// **'Study Room'**
  String get studyRoom;

  /// Dining room label
  ///
  /// In en, this message translates to:
  /// **'Dining Room'**
  String get diningRoom;

  /// Message shown when user name is updated successfully
  ///
  /// In en, this message translates to:
  /// **'Name updated successfully'**
  String get nameUpdated;

  /// Message shown when an update operation fails
  ///
  /// In en, this message translates to:
  /// **'Update failed'**
  String get updateError;

  /// Button to add a new friend
  ///
  /// In en, this message translates to:
  /// **'Add Friend'**
  String get addFriend;

  /// Placeholder for email input when adding a friend
  ///
  /// In en, this message translates to:
  /// **'Enter friend\'s email'**
  String get enterEmail;

  /// Generic add button text
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Message shown when adding a friend
  ///
  /// In en, this message translates to:
  /// **'Adding friend...'**
  String get addingFriend;

  /// Message shown when a friend is added successfully
  ///
  /// In en, this message translates to:
  /// **'Friend added successfully'**
  String get friendAdded;

  /// Message shown when adding a friend fails
  ///
  /// In en, this message translates to:
  /// **'Failed to add friend. The user may not exist or is already your friend.'**
  String get friendAddFailed;

  /// Title for room selection dialog
  ///
  /// In en, this message translates to:
  /// **'Select Room'**
  String get selectRoom;

  /// Message shown when loading rooms
  ///
  /// In en, this message translates to:
  /// **'Loading rooms...'**
  String get loadingRooms;

  /// Title for dialog to remove friend's access to a room
  ///
  /// In en, this message translates to:
  /// **'Remove Access'**
  String get removeAccess;

  /// Confirmation message for removing friend's access
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this friend\'s access to this room?'**
  String get confirmRemoveAccess;

  /// Message shown when access is removed
  ///
  /// In en, this message translates to:
  /// **'Access removed'**
  String get accessRemoved;

  /// Message shown when access is granted
  ///
  /// In en, this message translates to:
  /// **'Access granted'**
  String get accessGranted;

  /// Title for friend deletion dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Friend'**
  String get deleteFriend;

  /// Confirmation message for deleting a friend
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete friend {name}? All related room access permissions will also be removed.'**
  String confirmDeleteFriend(String name);

  /// Message shown when a friend is removed
  ///
  /// In en, this message translates to:
  /// **'Friend removed'**
  String get friendRemoved;

  /// Button to manage friends
  ///
  /// In en, this message translates to:
  /// **'Manage Friends'**
  String get manageFriends;

  /// Message shown when loading friends
  ///
  /// In en, this message translates to:
  /// **'Loading friends...'**
  String get loadingFriends;

  /// Message shown when no friends are available
  ///
  /// In en, this message translates to:
  /// **'No friends added yet'**
  String get noFriends;

  /// Close button text
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Message shown when a room is updated
  ///
  /// In en, this message translates to:
  /// **'Room updated'**
  String get roomUpdated;

  /// Title for the friends list
  ///
  /// In en, this message translates to:
  /// **'Friend List'**
  String get friendList;

  /// Tooltip for button to add friend to a room
  ///
  /// In en, this message translates to:
  /// **'Add to room'**
  String get addToRoom;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {

  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh': {
  switch (locale.countryCode) {
    case 'CN': return AppLocalizationsZhCn();
case 'TW': return AppLocalizationsZhTw();
   }
  break;
   }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
