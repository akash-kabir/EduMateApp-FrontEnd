import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/features/sapsync/provider/sap_provider.dart';
import 'package:app/features/sapsync/screens/sap_attendance_screen.dart';

class SapSetupScreen extends StatefulWidget {
  const SapSetupScreen({super.key});

  @override
  SapSetupScreenState createState() => SapSetupScreenState();
}

class SapSetupScreenState extends State<SapSetupScreen> {
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();

  List<String> _calculatedTerms = [];
  String? _selectedTerm;
  String _selectedSession = 'Autumn';
  final List<String> _sessions = ['Autumn', 'Spring'];

  @override
  void initState() {
    super.initState();
    _userIdController.addListener(_onUserIdChanged);
  }

  @override
  void dispose() {
    _userIdController.removeListener(_onUserIdChanged);
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onUserIdChanged() {
    final text = _userIdController.text.trim();
    if (text.length >= 2) {
      final yearStr = text.substring(0, 2);
      final yearInt = int.tryParse(yearStr);
      if (yearInt != null && yearInt > 10 && yearInt < 99) {
        final baseYear = 2000 + yearInt;
        final newTerms = [
          '$baseYear-${baseYear + 1} (1st Year)',
          '${baseYear + 1}-${baseYear + 2} (2nd Year)',
          '${baseYear + 2}-${baseYear + 3} (3rd Year)',
          '${baseYear + 3}-${baseYear + 4} (4th Year)',
        ];
        
        if (_calculatedTerms.join() != newTerms.join()) {
          setState(() {
            _calculatedTerms = newTerms;
            _selectedTerm = _calculatedTerms.first;
          });
        }
        return;
      }
    }
    
    if (_calculatedTerms.isNotEmpty) {
      setState(() {
        _calculatedTerms = [];
        _selectedTerm = null;
      });
    }
  }

  void _connect() async {
    final userId = _userIdController.text.trim();
    final password = _passwordController.text.trim();

    if (userId.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both User ID and Password')),
      );
      return;
    }

    if (_selectedTerm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid Roll Number to calculate term.')),
      );
      return;
    }

    // Example _selectedTerm: "2024-2025 (1st Year)", extract "2024-2025"
    final termYear = _selectedTerm!.substring(0, 9);
    
    // Pass 'Spring' or 'Autumn' directly so it matches the visible dropdown text 'Autumn Semester' / 'Spring Semester'
    final sessionKey = _selectedSession == 'Spring' ? 'Spring' : 'Autumn';

    final sapProvider = Provider.of<SapProvider>(context, listen: false);
    final success = await sapProvider.connect(userId, password, termYear, sessionKey);

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SapAttendanceScreen()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(sapProvider.errorMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sapProvider = Provider.of<SapProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[900], // Dark theme
      appBar: AppBar(
        title: const Text('Setup SapSync', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.sync_lock, size: 64, color: Colors.blueAccent),
            const SizedBox(height: 24),
            const Text(
              'Connect to SAP Portal',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.privacy_tip, color: Colors.greenAccent),
                  SizedBox(height: 8),
                  Text(
                    'Your password is encrypted and stored locally on this device only. It is never shared with our servers.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _userIdController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Roll Number (User ID)',
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            if (_calculatedTerms.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text('Select Academic Session', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: Colors.grey[800],
                          value: _selectedTerm,
                          isExpanded: true,
                          style: const TextStyle(color: Colors.white),
                          onChanged: (val) {
                            setState(() => _selectedTerm = val);
                          },
                          items: _calculatedTerms.map((term) {
                            return DropdownMenuItem(value: term, child: Text(term));
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: Colors.grey[800],
                          value: _selectedSession,
                          isExpanded: true,
                          style: const TextStyle(color: Colors.white),
                          onChanged: (val) {
                            setState(() => _selectedSession = val!);
                          },
                          items: _sessions.map((sess) {
                            return DropdownMenuItem(value: sess, child: Text(sess));
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 32),
            sapProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _connect,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Proceed to Connect', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
          ],
        ),
      ),
    );
  }
}
