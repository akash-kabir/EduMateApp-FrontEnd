// ignore_for_file: unused_field

import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../../config.dart';
import '../../services/shared_preferences_service.dart';
import '../../widgets/toast_manager.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  String postType = 'news';

  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _websiteLinkController = TextEditingController();
  final TextEditingController _registrationLinkController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  bool isDateRange = false;
  bool isTimeRange = false;
  bool isLoading = false;

  XFile? _selectedImage;
  bool _isUploadingImage = false;

  @override
  void dispose() {
    _bodyController.dispose();
    _websiteLinkController.dispose();
    _registrationLinkController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 900,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  void _removeImage() {
    setState(() => _selectedImage = null);
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;

    setState(() => _isUploadingImage = true);

    try {
      final token = await SharedPreferencesService.getToken();

      // Step 1: Get signed upload params from our backend
      final sigResponse = await http.get(
        Uri.parse(Config.uploadSignatureEndpoint),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (sigResponse.statusCode != 200) {
        String errorMsg =
            'Failed to get upload signature (${sigResponse.statusCode})';
        try {
          final body = jsonDecode(sigResponse.body);
          errorMsg = body['message'] ?? errorMsg;
        } catch (_) {}
        if (mounted) {
          EduMateToast.showCompact(
            context,
            message: errorMsg,
            isSuccess: false,
          );
        }
        return null;
      }

      final sigData = jsonDecode(sigResponse.body);
      final cloudName = sigData['cloudName'];
      final apiKey = sigData['apiKey'];
      final signature = sigData['signature'];
      final timestamp = sigData['timestamp'];
      final folder = sigData['folder'];
      final transformation = sigData['transformation'];

      // Step 2: Upload directly to Cloudinary (bypasses Vercel size limits)
      final uploadRequest = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload'),
      );
      uploadRequest.fields['signature'] = signature;
      uploadRequest.fields['api_key'] = apiKey;
      uploadRequest.fields['timestamp'] = timestamp.toString();
      uploadRequest.fields['folder'] = folder;
      uploadRequest.fields['transformation'] = transformation;
      uploadRequest.files.add(
        await http.MultipartFile.fromPath('file', _selectedImage!.path),
      );

      final streamedResponse = await uploadRequest.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['secure_url'];
      } else {
        String errorMsg = 'Upload failed (${response.statusCode})';
        try {
          final body = jsonDecode(response.body);
          errorMsg = body['error']?['message'] ?? errorMsg;
        } catch (_) {}
        if (mounted) {
          EduMateToast.showCompact(
            context,
            message: 'Image upload failed: $errorMsg',
            isSuccess: false,
          );
        }
        return null;
      }
    } catch (e) {
      if (mounted) {
        EduMateToast.showCompact(
          context,
          message: 'Image upload error: $e',
          isSuccess: false,
        );
      }
      return null;
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  void _selectDate(bool isStart) {
    DateTime? selectedDate = isStart
        ? startDate ?? DateTime.now()
        : endDate ?? DateTime.now();
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: 300,
        padding: const EdgeInsets.only(top: 6.0),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    child: const Text('Done'),
                    onPressed: () {
                      setState(() {
                        if (isStart) {
                          startDate = selectedDate;
                        } else {
                          endDate = selectedDate;
                        }
                      });
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  minimumDate: DateTime.now(),
                  maximumDate: DateTime(2100),
                  initialDateTime: isStart
                      ? startDate ?? DateTime.now()
                      : endDate ?? DateTime.now(),
                  onDateTimeChanged: (DateTime newDateTime) {
                    selectedDate = newDateTime;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectTime(bool isStart) {
    TimeOfDay selectedTime = isStart
        ? startTime ?? TimeOfDay.now()
        : endTime ?? TimeOfDay.now();
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: 300,
        padding: const EdgeInsets.only(top: 6.0),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    child: const Text('Done'),
                    onPressed: () {
                      setState(() {
                        if (isStart) {
                          startTime = selectedTime;
                        } else {
                          endTime = selectedTime;
                        }
                      });
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              Expanded(
                child: CupertinoTimerPicker(
                  mode: CupertinoTimerPickerMode.hm,
                  initialTimerDuration: Duration(
                    hours: selectedTime.hour,
                    minutes: selectedTime.minute,
                  ),
                  onTimerDurationChanged: (Duration duration) {
                    selectedTime = TimeOfDay(
                      hour: duration.inHours,
                      minute: duration.inMinutes % 60,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitPost() async {

    if (_bodyController.text.trim().isEmpty) {
      EduMateToast.showCompact(
        context,
        message: 'Body is required',
        isSuccess: false,
      );
      return;
    }

    if (postType == 'event') {
      if (startDate == null) {
        EduMateToast.showCompact(
          context,
          message: 'Start date is required for events',
          isSuccess: false,
        );
        return;
      }
      if (startTime == null) {
        EduMateToast.showCompact(
          context,
          message: 'Start time is required for events',
          isSuccess: false,
        );
        return;
      }
      if (isDateRange && endDate == null) {
        EduMateToast.showCompact(
          context,
          message: 'End date is required for date range',
          isSuccess: false,
        );
        return;
      }
      if (isTimeRange && endTime == null) {
        EduMateToast.showCompact(
          context,
          message: 'End time is required for time range',
          isSuccess: false,
        );
        return;
      }

    }

    setState(() => isLoading = true);

    try {
      // Upload image first if selected
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadImage();
        if (imageUrl == null) {
          // Upload failed, stop submission
          setState(() => isLoading = false);
          return;
        }
      }

      final token = await SharedPreferencesService.getToken();

      final Map<String, dynamic> body = {
        'postType': postType,
        'body': _bodyController.text.trim(),
        'websiteLink': _websiteLinkController.text.trim(),
        'registrationLink': _registrationLinkController.text.trim(),
        'location': _locationController.text.trim(),
      };

      if (imageUrl != null) {
        body['imageUrl'] = imageUrl;
      }

      if (postType == 'event') {
        body['eventDetails'] = {
          'startDate': startDate!.toIso8601String(),
          'endDate': isDateRange && endDate != null
              ? endDate!.toIso8601String()
              : null,
          'startTime':
              '${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}',
          'endTime': isTimeRange && endTime != null
              ? '${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}'
              : null,
          'isDateRange': isDateRange,
          'isTimeRange': isTimeRange,
        };
      }

      final response = await http.post(
        Uri.parse('${Config.BASE_URL}/api/posts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          EduMateToast.showCompact(
            context,
            message: 'Post created successfully!',
            isSuccess: true,
          );
          Navigator.pop(context, true);
        }
      } else {
        String errorMsg = 'Failed to create post (${response.statusCode})';
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic> && decoded.containsKey('message')) {
            errorMsg = decoded['message'];
          } else if (decoded is String) {
            errorMsg = decoded;
          }
        } catch (_) {}
        
        if (mounted) {
          EduMateToast.showCompact(
            context,
            message: errorMsg,
            isSuccess: false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        EduMateToast.showCompact(
          context,
          message: 'Error: $e',
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildSelectorCard({required String title, String? value, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: value != null ? const Color(0xFFFF9B7A).withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value ?? title,
              style: TextStyle(
                color: value != null ? Colors.white : Colors.white54,
                fontSize: 15,
                fontWeight: value != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Sleek solid dark background
      body: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            automaticallyImplyLeading: false,
            backgroundColor: CupertinoColors.black.withValues(alpha: 0.9),
            largeTitle: const Text('Create Post', style: TextStyle(color: Colors.white)),
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.pop(context),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.chevron_back, color: Color(0xFFFF9B7A)),
                  Text('Back', style: TextStyle(color: Color(0xFFFF9B7A))),
                ],
              ),
            ),
          ),
          SliverSafeArea(
            top: false,
            sliver: SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Modern Toggle Selector (matching WeekCalendarGrid style)
                      Container(
                        width: double.infinity,
                        height: 55,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFFF9B7A).withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => postType = 'news'),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: postType == 'news' ? const Color(0xFFFF9B7A) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.transparent,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'News',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: postType == 'news' ? Colors.white : Colors.grey[300],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => postType = 'event'),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: postType == 'event' ? const Color(0xFFFF9B7A) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.transparent,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Event',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: postType == 'event' ? Colors.white : Colors.grey[300],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),



                      SleekTextField(
                        title: 'Body',
                        controller: _bodyController,
                        placeholder: 'Enter body text',
                        icon: CupertinoIcons.text_alignleft,
                        maxLines: 5,
                        maxLength: postType == 'news' ? 200 : 50,
                        isRequired: true,
                      ),
                      const SizedBox(height: 32),

                      if (postType == 'event') ...[
                        _buildSectionTitle('Image'),
                        if (_selectedImage != null) ...[
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                children: [
                                  AspectRatio(
                                    aspectRatio: 4 / 3,
                                    child: Image.file(
                                      File(_selectedImage!.path),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: GestureDetector(
                                      onTap: _removeImage,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.6),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                        ),
                                        child: const Icon(CupertinoIcons.xmark, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton(
                              onPressed: _pickImage,
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFFFF9B7A),
                              ),
                              child: const Text('Change Image', style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ] else ...[
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              height: 160,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF9B7A).withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      CupertinoIcons.photo_on_rectangle,
                                      size: 32,
                                      color: Color(0xFFFF9B7A),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Tap to add an image',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    '4:3 ratio • Optional',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                      ],

                      _buildSectionTitle('Links'),
                      SleekTextField(
                        title: postType == 'event' ? 'Event Website' : 'Related Link',
                        controller: _websiteLinkController,
                        placeholder: 'Enter URL (Optional)',
                        icon: CupertinoIcons.link,
                      ),
                      
                      if (postType == 'event') ...[
                        const SizedBox(height: 24),
                        SleekTextField(
                          title: 'Registration Link',
                          controller: _registrationLinkController,
                          placeholder: 'Enter registration URL (Optional)',
                          icon: CupertinoIcons.ticket,
                        ),
                        const SizedBox(height: 32),

                        _buildSectionTitle('Location'),
                        SleekTextField(
                          title: 'Location',
                          controller: _locationController,
                          placeholder: 'Enter location (Max 25 words)',
                          icon: CupertinoIcons.location_solid,
                        ),
                        const SizedBox(height: 32),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSectionTitle('Date'),
                            Row(
                              children: [
                                const Text('Multiple Days', style: TextStyle(color: Colors.white, fontSize: 14)),
                                const SizedBox(width: 8),
                                CupertinoSwitch(
                                  value: isDateRange,
                                  activeTrackColor: const Color(0xFFFF9B7A),
                                  onChanged: (val) => setState(() => isDateRange = val),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Date Selection
                        Row(
                          children: [
                            Expanded(
                                child: _buildSelectorCard(
                                  title: 'Start Date *',
                                  value: startDate == null ? null : "${startDate!.day.toString().padLeft(2, '0')}/${startDate!.month.toString().padLeft(2, '0')}/${startDate!.year}",
                                  onTap: () => _selectDate(true),
                                ),
                            ),
                            if (isDateRange) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                  child: _buildSelectorCard(
                                    title: 'End Date *',
                                    value: endDate == null ? null : "${endDate!.day.toString().padLeft(2, '0')}/${endDate!.month.toString().padLeft(2, '0')}/${endDate!.year}",
                                    onTap: () => _selectDate(false),
                                  ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 32),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSectionTitle('Time'),
                            Row(
                              children: [
                                const Text('Time Range', style: TextStyle(color: Colors.white, fontSize: 14)),
                                const SizedBox(width: 8),
                                CupertinoSwitch(
                                  value: isTimeRange,
                                  activeTrackColor: const Color(0xFFFF9B7A),
                                  onChanged: (val) => setState(() => isTimeRange = val),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                                child: _buildSelectorCard(
                                  title: 'Start Time *',
                                  value: startTime == null ? null : "${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}",
                                  onTap: () => _selectTime(true),
                                ),
                            ),
                            if (isTimeRange) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                  child: _buildSelectorCard(
                                    title: 'End Time *',
                                    value: endTime == null ? null : "${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}",
                                    onTap: () => _selectTime(false),
                                  ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 32),
                      ],

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF9B7A).withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _submitPost,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF9B7A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text(
                                    'Create Post',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SleekTextField extends StatefulWidget {
  final String title;
  final TextEditingController controller;
  final String placeholder;
  final int maxLines;
  final bool isRequired;
  final IconData icon;
  final int? maxLength;

  const SleekTextField({
    super.key,
    required this.title,
    required this.controller,
    required this.placeholder,
    required this.icon,
    this.maxLines = 1,
    this.isRequired = false,
    this.maxLength,
  });

  @override
  State<SleekTextField> createState() => _SleekTextFieldState();
}

class _SleekTextFieldState extends State<SleekTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (widget.isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  color: Color(0xFFE63946),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isFocused ? const Color(0xFFFF9B7A) : Colors.white.withValues(alpha: 0.05),
              width: _isFocused ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: _isFocused ? const Color(0xFFFF9B7A).withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.3),
                blurRadius: _isFocused ? 12 : 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: widget.maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 16, top: widget.maxLines > 1 ? 16 : 14, right: 8, bottom: widget.maxLines > 1 ? 0 : 14),
                child: Icon(
                  widget.icon,
                  color: _isFocused ? const Color(0xFFFF9B7A) : Colors.grey[500],
                  size: 20,
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  maxLines: widget.maxLines,
                  maxLength: widget.maxLength,
                  style: const TextStyle(fontSize: 15, color: Colors.white),
                  decoration: InputDecoration(
                    counterStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                    hintText: widget.placeholder,
                    hintStyle: TextStyle(color: Colors.grey[600], fontSize: 15),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.only(
                      right: 16,
                      top: widget.maxLines > 1 ? 14 : 14,
                      bottom: widget.maxLines > 1 ? 14 : 14,
                    ),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
