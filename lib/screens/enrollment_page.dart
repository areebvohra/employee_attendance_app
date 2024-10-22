import 'dart:math';

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EnrollmentPage extends StatefulWidget {
  @override
  _EnrollmentPageState createState() => _EnrollmentPageState();
}

class _EnrollmentPageState extends State<EnrollmentPage> {
  final LocalAuthentication _localAuthentication = LocalAuthentication();
  late SharedPreferences _prefs;
  String _employeeId = '';
  bool _isFaceIdEnrolled = false;

  @override
  void initState() {
    super.initState();
    _generateUniqueEmployeeId();
    _checkFaceIdEnrolled();
  }

  Future<void> _generateUniqueEmployeeId() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _employeeId = 'EMP-${Random().nextInt(10000).toString().padLeft(4, '0')}';
    });
    await _prefs.setString('employeeId', _employeeId);
  }

  Future<void> _checkFaceIdEnrolled() async {
    bool canAuthenticate = await _localAuthentication.canCheckBiometrics;
    if (canAuthenticate) {
      List<BiometricType> availableBiometrics =
          await _localAuthentication.getAvailableBiometrics();
      setState(() {
        _isFaceIdEnrolled = availableBiometrics.contains(BiometricType.face);
      });
    }
  }

  Future<void> _enrollFaceID() async {
    bool canEnroll = await _localAuthentication.authenticate(
      localizedReason: 'Enroll your face for attendance',
      options: const AuthenticationOptions(
        stickyAuth: true,
        biometricOnly: true,
      ),
    );
    if (canEnroll) {
      // Save the enrolled face ID in the shared preferences
      // You would need to integrate with a biometric authentication service for this
      print('Face ID enrolled successfully!');
      setState(() {
        _isFaceIdEnrolled = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enroll Employee'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Your Employee ID: $_employeeId'),
            const SizedBox(height: 16),
            if (_isFaceIdEnrolled) Text('Your face ID is already enrolled.'),
            if (!_isFaceIdEnrolled)
              ElevatedButton(
                onPressed: _enrollFaceID,
                child: const Text('Enroll Face ID'),
              ),
          ],
        ),
      ),
    );
  }
}
