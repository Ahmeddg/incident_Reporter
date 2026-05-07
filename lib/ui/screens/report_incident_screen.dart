import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:incident_reporter/core/models/incident.dart';
import 'package:incident_reporter/ui/controllers/emergency_controller.dart';
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
  final EmergencyController _controller = Get.find<EmergencyController>();

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
  Coordinates _coordinates = const Coordinates(lat: 0, lng: 0);

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

      _coordinates = Coordinates(
        lat: position.latitude,
        lng: position.longitude,
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final bool created = await _controller.submitIncident(
      emergencyType: _selectedType,
      severity: _selectedSeverity,
      location: _locationController.text.trim(),
      description: _notesController.text.trim(),
      coordinates: _coordinates,
    );

    if (!mounted) {
      return;
    }

    if (!created) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _controller.errorMessage.value.isEmpty
                ? 'Could not submit incident.'
                : _controller.errorMessage.value,
          ),
        ),
      );
      return;
    }

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
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF6F1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFD3BD)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.warning_amber_rounded, color: Color(0xFFC2410C)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Tell us what happened',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'We will create an emergency alert and guide you while help is coming.',
                          style: TextStyle(color: Color(0xFF5E6A72)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const _SectionLabel('Emergency type'),
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.emergency_share_outlined),
              ),
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
            const _SectionLabel('Severity'),
            DropdownButtonFormField<String>(
              initialValue: _selectedSeverity,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.priority_high_rounded),
              ),
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
            const _SectionLabel('Location'),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                hintText: 'Street, district, or nearby landmark',
                prefixIcon: Icon(Icons.location_on_outlined),
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
            const _SectionLabel('Situation details'),
            TextFormField(
              controller: _notesController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText:
                    'Example: 2 injured people, heavy smoke, blocked road...',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF7FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFCFE8FF)),
              ),
              child: const Row(
                children: <Widget>[
                  Icon(Icons.info_outline_rounded, color: Color(0xFF16697A)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Use GPS to auto-fill location, or type it manually.',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Obx(
              () => SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _controller.isSubmitting.value ? null : _submit,
                  icon: _controller.isSubmitting.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: const Text('Submit Emergency Report'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF34444C),
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
