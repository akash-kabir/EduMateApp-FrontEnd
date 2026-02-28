import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../../config.dart';
import '../../services/shared_preferences_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  String postType = 'news';

  final TextEditingController _headingController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _websiteLinkController = TextEditingController();
  final TextEditingController _registrationLinkController =
      TextEditingController();
  final TextEditingController _campusController = TextEditingController();
  final TextEditingController _floorController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();

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
    _headingController.dispose();
    _bodyController.dispose();
    _websiteLinkController.dispose();
    _registrationLinkController.dispose();
    _campusController.dispose();
    _floorController.dispose();
    _roomController.dispose();
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMsg)));
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image upload failed: $errorMsg')),
          );
        }
        return null;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Image upload error: $e')));
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
    if (_headingController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Heading is required')));
      return;
    }
    if (_bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Body is required')));
      return;
    }

    if (postType == 'event') {
      if (startDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Start date is required for events')),
        );
        return;
      }
      if (startTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Start time is required for events')),
        );
        return;
      }
      if (isDateRange && endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End date is required for date range')),
        );
        return;
      }
      if (isTimeRange && endTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End time is required for time range')),
        );
        return;
      }
      if (_campusController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Campus is required for events')),
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

      final body = {
        'postType': postType,
        'heading': _headingController.text.trim(),
        'body': _bodyController.text.trim(),
        'links': {
          'website': _websiteLinkController.text.trim(),
          'registration': _registrationLinkController.text.trim(),
        },
        'location': {
          'campus': _campusController.text.trim(),
          'floor': _floorController.text.trim(),
          'roomNo': _roomController.text.trim(),
        },
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post created successfully!')),
          );
          Navigator.pop(context, true);
        }
      } else {
        final error = jsonDecode(response.body)['message'];
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error)));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            automaticallyImplyLeading: false,
            backgroundColor: isDark
                ? CupertinoColors.black.withOpacity(0.9)
                : CupertinoColors.white.withOpacity(0.9),
            largeTitle: const Text('Create Post'),
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.pop(context),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [Icon(CupertinoIcons.chevron_back), Text('Back')],
              ),
            ),
          ),
          SliverSafeArea(
            top: false,
            sliver: SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Post Type Selector
                      SizedBox(
                        width: double.infinity,
                        child: CupertinoSlidingSegmentedControl<String>(
                          backgroundColor: CupertinoColors.systemGrey6
                              .resolveFrom(context),
                          thumbColor: CupertinoColors.systemBackground
                              .resolveFrom(context),
                          groupValue: postType,
                          onValueChanged: (String? value) {
                            if (value != null) {
                              setState(() => postType = value);
                            }
                          },
                          children: {
                            'news': Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 12,
                              ),
                              child: const Text(
                                'News',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            'event': Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 12,
                              ),
                              child: const Text(
                                'Event',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title Field
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Text(
                              'Title',
                              style: TextStyle(
                                color: CupertinoColors.secondaryLabel
                                    .resolveFrom(context),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              ' *',
                              style: TextStyle(
                                color: CupertinoColors.systemRed,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey6.resolveFrom(
                            context,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: CupertinoTextField.borderless(
                          controller: _headingController,
                          placeholder: 'Enter heading',
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Body Field
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Text(
                              'Body',
                              style: TextStyle(
                                color: CupertinoColors.secondaryLabel
                                    .resolveFrom(context),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              ' *',
                              style: TextStyle(
                                color: CupertinoColors.systemRed,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey6.resolveFrom(
                            context,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: CupertinoTextField.borderless(
                          controller: _bodyController,
                          placeholder: 'Enter body text',
                          maxLines: 5,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Image Section
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Image',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      if (_selectedImage != null) ...[
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: AspectRatio(
                                aspectRatio: 4 / 3,
                                child: Image.file(
                                  File(_selectedImage!.path),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: _removeImage,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.xmark,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: _pickImage,
                            child: const Text('Change Image'),
                          ),
                        ),
                      ] else ...[
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            height: 150,
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey6.resolveFrom(
                                context,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: CupertinoColors.systemGrey4.resolveFrom(
                                  context,
                                ),
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    CupertinoIcons.photo,
                                    size: 40,
                                    color: CupertinoColors.secondaryLabel
                                        .resolveFrom(context),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Add Image (Optional)',
                                    style: TextStyle(
                                      color: CupertinoColors.secondaryLabel
                                          .resolveFrom(context),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '4:3 ratio • Max 5MB',
                                    style: TextStyle(
                                      color: CupertinoColors.tertiaryLabel
                                          .resolveFrom(context),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Links Section
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Links',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),

                      // Website Link
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Website Link',
                          style: TextStyle(
                            color: CupertinoColors.secondaryLabel.resolveFrom(
                              context,
                            ),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey6.resolveFrom(
                            context,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: CupertinoTextField.borderless(
                          controller: _websiteLinkController,
                          placeholder: 'Enter website link (Optional)',
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Registration Link
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Registration Link',
                          style: TextStyle(
                            color: CupertinoColors.secondaryLabel.resolveFrom(
                              context,
                            ),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey6.resolveFrom(
                            context,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: CupertinoTextField.borderless(
                          controller: _registrationLinkController,
                          placeholder: 'Enter registration link (Optional)',
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Location Section
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Location',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),

                      // Campus
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Text(
                              'Campus',
                              style: TextStyle(
                                color: CupertinoColors.secondaryLabel
                                    .resolveFrom(context),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (postType == 'event')
                              Text(
                                ' *',
                                style: TextStyle(
                                  color: CupertinoColors.systemRed,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey6.resolveFrom(
                            context,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: CupertinoTextField.borderless(
                          controller: _campusController,
                          placeholder:
                              'Enter campus name${postType == 'event' ? '' : ' (Optional)'}',
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Floor
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Floor',
                          style: TextStyle(
                            color: CupertinoColors.secondaryLabel.resolveFrom(
                              context,
                            ),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey6.resolveFrom(
                            context,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: CupertinoTextField.borderless(
                          controller: _floorController,
                          placeholder: 'Enter floor number (Optional)',
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Room Number
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Room Number',
                          style: TextStyle(
                            color: CupertinoColors.secondaryLabel.resolveFrom(
                              context,
                            ),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey6.resolveFrom(
                            context,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: CupertinoTextField.borderless(
                          controller: _roomController,
                          placeholder: 'Enter room number (Optional)',
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Event Details
                      if (postType == 'event') ...[
                        // Date Section
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              Text(
                                'Date',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              Text(
                                ' *',
                                style: TextStyle(
                                  color: CupertinoColors.systemRed,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Date Range Toggle
                        Row(
                          children: [
                            Text(
                              'Date Range',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const Spacer(),
                            CupertinoSwitch(
                              value: isDateRange,
                              onChanged: (val) =>
                                  setState(() => isDateRange = val),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Date Selection
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _selectDate(true),
                                icon: const Icon(Icons.calendar_today),
                                label: Text(
                                  startDate == null
                                      ? 'Start Date *'
                                      : '${startDate!.day}/${startDate!.month}/${startDate!.year}',
                                ),
                              ),
                            ),
                            if (isDateRange) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _selectDate(false),
                                  icon: const Icon(Icons.calendar_today),
                                  label: Text(
                                    endDate == null
                                        ? 'End Date *'
                                        : '${endDate!.day}/${endDate!.month}/${endDate!.year}',
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Time Section
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              Text(
                                'Time',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              Text(
                                ' *',
                                style: TextStyle(
                                  color: CupertinoColors.systemRed,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Time Range Toggle
                        Row(
                          children: [
                            Text(
                              'Time Range',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const Spacer(),
                            CupertinoSwitch(
                              value: isTimeRange,
                              onChanged: (val) =>
                                  setState(() => isTimeRange = val),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Time Selection
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _selectTime(true),
                                icon: const Icon(Icons.access_time),
                                label: Text(
                                  startTime == null
                                      ? 'Start Time *'
                                      : '${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}',
                                ),
                              ),
                            ),
                            if (isTimeRange) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _selectTime(false),
                                  icon: const Icon(Icons.access_time),
                                  label: Text(
                                    endTime == null
                                        ? 'End Time *'
                                        : '${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}',
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: isLoading ? null : _submitPost,
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Create Post'),
                        ),
                      ),
                      const SizedBox(height: 24),
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
