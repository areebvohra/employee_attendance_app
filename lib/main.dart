import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/enrollment_page.dart';

void main() {
  runApp(EmployeeAttendanceApp());
}

class EmployeeAttendanceApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Employee Attendance',
      home: AttendancePage(),
      routes: {
        '/enroll': (context) => EnrollmentPage(),
      },
    );
  }
}

class AttendancePage extends StatefulWidget {
  @override
  _AttendancePageState createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final LocalAuthentication _localAuthentication = LocalAuthentication();
  late SharedPreferences _prefs;
  DateTime? _checkInTime;
  DateTime? _checkOutTime;
  String? _employeeId;

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
  }

  Future<void> _loadAttendanceData() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _checkInTime = _prefs.getString('checkInTime') != null
          ? DateTime.parse(_prefs.getString('checkInTime')!)
          : null;
      _checkOutTime = _prefs.getString('checkOutTime') != null
          ? DateTime.parse(_prefs.getString('checkOutTime')!)
          : null;
      _employeeId = _prefs.getString('employeeId');
    });
  }

  Future<void> _handleCheckIn() async {
    bool canCheckIn = await _authenticateWithFaceID();
    if (canCheckIn) {
      if (_checkInTime == null && _employeeId != null) {
        setState(() {
          _checkInTime = DateTime.now();
        });
        await _prefs.setString('checkInTime', _checkInTime.toString());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'You have already checked in for today or your employee ID is missing.'),
          ),
        );
      }
    }
  }

  Future<void> _handleCheckOut() async {
    bool canCheckOut = await _authenticateWithFaceID();
    if (canCheckOut) {
      if (_checkOutTime == null &&
          _checkInTime != null &&
          _employeeId != null) {
        setState(() {
          _checkOutTime = DateTime.now();
        });
        await _prefs.setString('checkOutTime', _checkOutTime.toString());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'You have already checked out for today or your employee ID is missing.'),
          ),
        );
      }
    }
  }

  Future<bool> _authenticateWithFaceID() async {
    bool authenticated = false;
    try {
      authenticated = await _localAuthentication.authenticate(
        localizedReason: 'Authenticate to check in/out',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      print('Error authenticating: $e');
    }
    return authenticated;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, '/enroll');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _employeeId = value;
                  });
                  _prefs.setString('employeeId', value);
                },
                decoration: const InputDecoration(
                  hintText: 'Enter Employee ID',
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_checkInTime != null)
              Text(
                  'Checked in at: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(_checkInTime!)}'),
            const SizedBox(height: 16),
            if (_checkOutTime != null)
              Text(
                  'Checked out at: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(_checkOutTime!)}'),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _handleCheckIn,
              child: const Text('Check In'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _handleCheckOut,
              child: const Text('Check Out'),
            ),
          ],
        ),
      ),
    );
  }
}
