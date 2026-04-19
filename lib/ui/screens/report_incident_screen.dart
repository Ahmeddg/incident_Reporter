import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:incident_reporter/core/services/mock_emergency_service.dart';
import 'package:incident_reporter/ui/screens/incident_tracker_screen.dart';

class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final MockEmergencyService _service = MockEmergencyService();

  final List<String> _types = <String>[
    'Road Accident',
    'Breathing Emergency',
    'Cardiac Symptoms',
    'Fire Injury',
    'Violence / Assault',
    'Other',
  ];

  final List<String> _severities = <String>[
    'Critical',
    'High',
    'Medium',
    'Low'
  ];

  String _selectedType = 'Road Accident';
  String _selectedSeverity = 'High';
  bool _isFetchingLocation = false;

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fillWithCurrentGps() async {
    if (_isFetchingLocation) {
      return;
    }

    setState(() => _isFetchingLocation = true);

    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location service is disabled. Please enable GPS.'),
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Location permission is required to use current GPS.'),
            ),
          );
        }
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _locationController.text =
          'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Current GPS coordinates inserted.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get your current location.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isFetchingLocation = false);
      }
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _service.submitIncident(
      emergencyType: _selectedType,
      severity: _selectedSeverity,
      location: _locationController.text.trim(),
      description: _notesController.text.trim(),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const IncidentTrackerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Emergency')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            const Text(
              'Tell us what happened',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'We will create an emergency alert and guide you while help is coming.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(labelText: 'Emergency Type'),
              items: _types
                  .map((String item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      ))
                  .toList(),
              onChanged: (String? value) {
                if (value == null) {
                  return;
                }
                setState(() => _selectedType = value);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedSeverity,
              decoration: const InputDecoration(labelText: 'Severity'),
              items: _severities
                  .map((String item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      ))
                  .toList(),
              onChanged: (String? value) {
                if (value == null) {
                  return;
                }
                setState(() => _selectedSeverity = value);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Your Location',
                hintText: 'Street, district, or nearby landmark',
              ),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Location is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _isFetchingLocation ? null : _fillWithCurrentGps,
                icon: _isFetchingLocation
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_rounded),
                label: const Text('Use my current GPS'),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Situation Details (optional)',
                hintText:
                    'Example: 2 injured people, heavy smoke, blocked road...',
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF7FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCFE8FF)),
              ),
              child: const Text(
                'Tap "Use my current GPS" to auto-fill location, or type location manually.',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.send_rounded),
                label: const Text('Submit Emergency Report'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
