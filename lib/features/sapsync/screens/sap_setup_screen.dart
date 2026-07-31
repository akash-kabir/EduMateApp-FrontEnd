import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/features/sapsync/provider/sap_provider.dart';
import 'package:app/features/sapsync/screens/sap_attendance_screen.dart';
import 'package:app/shared/widgets/dialogs/toast_manager.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Future<bool> _connect() async {
    final userId = _userIdController.text.trim();
    final password = _passwordController.text.trim();

    if (userId.isEmpty || password.isEmpty) {
      EduMateToast.showCompact(context, message: 'Please enter both User ID and Password', isSuccess: false);
      return false;
    }

    if (_selectedTerm == null) {
      EduMateToast.showCompact(context, message: 'Please enter a valid Roll Number to calculate term.', isSuccess: false);
      return false;
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
      EduMateToast.showCompact(context, message: sapProvider.errorMessage, isSuccess: false);
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final sapProvider = Provider.of<SapProvider>(context);

    return Scaffold(
      backgroundColor: Colors.black, // Pitch black theme
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar: Back Button & Title Centered
              Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Hero(
                      tag: 'back_button',
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Color(0xFF141110), // Sleek coal
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(CupertinoIcons.back, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const Text(
                    'SapSync',
                    style: TextStyle(
                      fontSize: 28,
                      fontFamily: 'Salena',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Color(0xFFFF9B7A), // Coral
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Elaborated Disclaimer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF141110), // Sleek coal
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFF9B7A).withOpacity(0.5), width: 1),
                ),
                child: Text(
                  'Your SAP credentials are encrypted locally on this device. We never store or share your password with any external servers.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[400], fontSize: 13, height: 1.4),
                ),
              ),
              const SizedBox(height: 32),
              
              // Roll Number Field
              TextField(
                controller: _userIdController,
                keyboardType: TextInputType.number, // strictly just numpad
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Roll Number (User ID)',
                  labelStyle: TextStyle(color: Colors.grey[500]),
                  filled: true,
                  fillColor: const Color(0xFF141110),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                ),
              ),
              const SizedBox(height: 16),
              
              // Password Field
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Colors.grey[500]),
                  filled: true,
                  fillColor: const Color(0xFF141110),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                ),
              ),
              
              // Dynamic Dropdowns (Term & Session)
              if (_calculatedTerms.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Academic Year', style: TextStyle(color: Colors.grey[400], fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141110),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      dropdownColor: const Color(0xFF141110),
                      value: _selectedTerm,
                      isExpanded: true,
                      icon: const Icon(CupertinoIcons.chevron_down, color: Colors.grey, size: 16),
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      onChanged: (val) {
                        setState(() => _selectedTerm = val);
                      },
                      items: _calculatedTerms.map((term) {
                        return DropdownMenuItem(value: term, child: Text(term));
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Semester', style: TextStyle(color: Colors.grey[400], fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141110),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      dropdownColor: const Color(0xFF141110),
                      value: _selectedSession,
                      isExpanded: true,
                      icon: const Icon(CupertinoIcons.chevron_down, color: Colors.grey, size: 16),
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      onChanged: (val) {
                        setState(() => _selectedSession = val!);
                      },
                      items: _sessions.map((sess) {
                        return DropdownMenuItem(value: sess, child: Text(sess));
                      }).toList(),
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 48),
              
              // Slide to Login Button
              SlideToLoginButton(
                isLoading: sapProvider.isLoading,
                onSlideComplete: _connect,
              ),
                    
              const SizedBox(height: 16),
              
              // Learn More Button
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () async {
                  final url = Uri.parse('https://edumateapp.com/sapsync-info.html');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    if (mounted) {
                      EduMateToast.showCompact(context, message: 'Could not open link', isSuccess: false);
                    }
                  }
                },
                child: const Text(
                  'Learn more about SapSync',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SlideToLoginButton extends StatefulWidget {
  final Future<bool> Function() onSlideComplete;
  final bool isLoading;

  const SlideToLoginButton({
    Key? key,
    required this.onSlideComplete,
    this.isLoading = false,
  }) : super(key: key);

  @override
  SlideToLoginButtonState createState() => SlideToLoginButtonState();
}

class SlideToLoginButtonState extends State<SlideToLoginButton> with SingleTickerProviderStateMixin {
  double _dragPosition = 0.0;
  bool _isCompleted = false;
  final double _buttonHeight = 60.0;
  final double _thumbSize = 52.0;

  @override
  void didUpdateWidget(covariant SlideToLoginButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isLoading && oldWidget.isLoading && _isCompleted) {
      // If loading finishes (e.g. error), reset the slider
      setState(() {
        _dragPosition = 0;
        _isCompleted = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDrag = constraints.maxWidth - _buttonHeight;
        
        return Container(
          height: _buttonHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF141110), // Sleek coal background
            borderRadius: BorderRadius.circular(_buttonHeight / 2),
            border: Border.all(color: const Color(0xFFFF9B7A).withOpacity(0.3), width: 1),
          ),
          child: Stack(
            children: [
              // Background Text
              Center(
                child: Text(
                  widget.isLoading ? 'Authenticating...' : 'Slide to Login',
                  style: TextStyle(
                    color: widget.isLoading ? const Color(0xFFFF9B7A) : Colors.grey[400],
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              // Loading indicator
              if (widget.isLoading)
                const Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: 20.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF9B7A),
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),
              // The Draggable Thumb
              if (!widget.isLoading && !_isCompleted)
                Positioned(
                  left: _dragPosition,
                  top: (_buttonHeight - _thumbSize) / 2,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        _dragPosition += details.delta.dx;
                        if (_dragPosition < 0) _dragPosition = 0;
                        if (_dragPosition > maxDrag) _dragPosition = maxDrag;
                      });
                    },
                    onPanEnd: (details) async {
                      if (_dragPosition > maxDrag * 0.8) {
                        setState(() {
                          _dragPosition = maxDrag;
                          _isCompleted = true;
                        });
                        bool success = await widget.onSlideComplete();
                        if (!success && mounted) {
                          setState(() {
                            _dragPosition = 0;
                            _isCompleted = false;
                          });
                        }
                      } else {
                        // Snap back
                        setState(() {
                          _dragPosition = 0;
                        });
                      }
                    },
                    child: Container(
                      width: _thumbSize,
                      height: _thumbSize,
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9B7A), // Coral thumb
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF9B7A).withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        CupertinoIcons.chevron_right_2,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      }
    );
  }
}
