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
import '../../models/poi_model.dart';
import '../../services/poi_service.dart';

import 'package:image_cropper/image_cropper.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  String postType = 'news';

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _websiteLinkController = TextEditingController();
  final TextEditingController _registrationLinkController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _floorController = TextEditingController();
  final TextEditingController _roomNoController = TextEditingController();

  List<PoiModel> _pois = [];
  PoiModel? _selectedPoi;
  bool _isLoadingPois = false;

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
  void initState() {
    super.initState();
    _loadPois();
  }

  Future<void> _loadPois() async {
    setState(() => _isLoadingPois = true);
    try {
      final pois = await PoiService.getPOIs();
      if (mounted) {
        setState(() {
          _pois = pois;
          _isLoadingPois = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingPois = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _websiteLinkController.dispose();
    _registrationLinkController.dispose();
    _locationController.dispose();
    _floorController.dispose();
    _roomNoController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );

    if (image != null) {
      try {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          aspectRatio: const CropAspectRatio(ratioX: 4, ratioY: 5),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Image (4:5)',
              toolbarColor: const Color(0xFF1E1E1E),
              toolbarWidgetColor: Colors.white,
              activeControlsWidgetColor: const Color(0xFFFF9B7A),
              lockAspectRatio: true,
            ),
            IOSUiSettings(
              title: 'Crop Image (4:5)',
              aspectRatioLockEnabled: true,
              resetAspectRatioEnabled: false,
            ),
          ],
        );

        if (croppedFile != null) {
          setState(() => _selectedImage = XFile(croppedFile.path));
        }
      } catch (e) {
        // Fallback to uncropped image if native cropper plugin channel is missing (requires full app restart)
        if (mounted) {
          setState(() => _selectedImage = image);
        }
      }
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
      if (sigData['transformation'] != null && sigData['transformation'].toString().isNotEmpty) {
        uploadRequest.fields['transformation'] = sigData['transformation'].toString();
      }
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
    FocusScope.of(context).requestFocus(FocusNode());
    DateTime initialDate = isStart
        ? startDate ?? DateTime.now()
        : endDate ?? DateTime.now();
    DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    DateTime minDate = initialDate.isBefore(today) ? initialDate : today;
    DateTime tempSelectedDate = initialDate;

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
                          startDate = tempSelectedDate;
                        } else {
                          endDate = tempSelectedDate;
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
                  minimumDate: minDate,
                  maximumDate: DateTime(2100),
                  initialDateTime: initialDate,
                  onDateTimeChanged: (DateTime newDateTime) {
                    tempSelectedDate = newDateTime;
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
    FocusScope.of(context).requestFocus(FocusNode());
    TimeOfDay initialTime = isStart
        ? startTime ?? TimeOfDay.now()
        : endTime ?? TimeOfDay.now();
    TimeOfDay tempSelectedTime = initialTime;

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
                          startTime = tempSelectedTime;
                        } else {
                          endTime = tempSelectedTime;
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
                    hours: initialTime.hour,
                    minutes: initialTime.minute,
                  ),
                  onTimerDurationChanged: (Duration duration) {
                    tempSelectedTime = TimeOfDay(
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

  void _showPoiPickerModal(BuildContext context) {
    String searchQuery = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (stCtx, setModalState) {
            final filteredPois = _pois.where((poi) {
              final query = searchQuery.trim().toLowerCase();
              if (query.isEmpty) return true;
              return poi.name.toLowerCase().contains(query) ||
                  poi.address.toLowerCase().contains(query) ||
                  poi.type.toLowerCase().contains(query);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Top Handle & Header
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(CupertinoIcons.compass_fill, color: Color(0xFFFF9B7A), size: 22),
                            SizedBox(width: 10),
                            Text(
                              'Select Navigation Target',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(CupertinoIcons.xmark_circle_fill, color: Colors.white54),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: CupertinoSearchTextField(
                      backgroundColor: Colors.black38,
                      style: const TextStyle(color: Colors.white),
                      placeholder: 'Search POIs by name or type...',
                      onChanged: (val) {
                        setModalState(() {
                          searchQuery = val;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white10, height: 1),

                  // POI List
                  Expanded(
                    child: filteredPois.isEmpty
                        ? const Center(
                            child: Text(
                              'No matching POIs found',
                              style: TextStyle(color: Colors.white54, fontSize: 14),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredPois.length,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemBuilder: (ctx, index) {
                              final poi = filteredPois[index];
                              final isSelected = _selectedPoi?.id == poi.id;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFFF9B7A).withValues(alpha: 0.15)
                                      : Colors.white.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFFF9B7A)
                                        : Colors.white.withValues(alpha: 0.08),
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFFFF9B7A) : Colors.white10,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      CupertinoIcons.location_solid,
                                      color: isSelected ? Colors.black : Colors.white70,
                                      size: 18,
                                    ),
                                  ),
                                  title: Text(
                                    poi.name,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  subtitle: poi.address.isNotEmpty
                                      ? Text(
                                          poi.address,
                                          style: const TextStyle(color: Colors.white54, fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        )
                                      : null,
                                  trailing: isSelected
                                      ? const Icon(CupertinoIcons.checkmark_circle_fill, color: Color(0xFFFF9B7A))
                                      : const Icon(CupertinoIcons.chevron_right, color: Colors.white24, size: 16),
                                  onTap: () {
                                    setState(() {
                                      _selectedPoi = poi;
                                      _locationController.text = poi.name;
                                    });
                                    Navigator.pop(modalCtx);
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _submitPost() async {

    if (_titleController.text.trim().isEmpty) {
      EduMateToast.showCompact(context,
          message: 'Please enter a title', isSuccess: false);
      return;
    }
    if (_selectedImage == null) {
      EduMateToast.showCompact(context,
          message: 'An image is required', isSuccess: false);
      return;
    }
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
        'title': _titleController.text.trim(),
        'body': _bodyController.text.trim(),
        'websiteLink': _websiteLinkController.text.trim(),
        'registrationLink': _registrationLinkController.text.trim(),
        'location': {
          'campus': _locationController.text.trim(),
          'floor': _floorController.text.trim(),
          'roomNo': _roomNoController.text.trim(),
          if (_selectedPoi != null) 'poiId': _selectedPoi!.id,
          if (_selectedPoi != null) 'poiName': _selectedPoi!.name,
          if (_selectedPoi != null) 'poiLat': _selectedPoi!.lat,
          if (_selectedPoi != null) 'poiLng': _selectedPoi!.lng,
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

  Widget _buildSectionTitle(String title, {bool isRequired = false, bool hasValue = false}) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 8),
          hasValue
              ? const Icon(CupertinoIcons.checkmark_alt_circle_fill, color: Colors.green, size: 18)
              : const Icon(CupertinoIcons.check_mark_circled, color: Color(0xFFE63946), size: 18),
        ],
      ],
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
                      const SizedBox(height: 16),
                      // Title Input
                      SleekTextField(
                        title: 'Title',
                        controller: _titleController,
                        placeholder: 'Enter post title',
                        icon: CupertinoIcons.text_quote,
                        isRequired: true,
                        maxLength: 25,
                      ),
                      const SizedBox(height: 16),

                      SleekTextField(
                        title: 'Body',
                        controller: _bodyController,
                        placeholder: 'Enter body text',
                        icon: CupertinoIcons.text_alignleft,
                        maxLines: 5,
                        maxLength: 200,
                        isRequired: true,
                      ),
                      const SizedBox(height: 32),

                      _buildSectionTitle('Image', isRequired: true, hasValue: _selectedImage != null),
                      const SizedBox(height: 16),
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
                                    aspectRatio: 4 / 5,
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
                                    '4:3 ratio • Required',
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

                      _buildSectionTitle('Links'),
                      const SizedBox(height: 16),
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

                        _buildSectionTitle('Navigation Target (POI)'),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () => _showPoiPickerModal(context),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _selectedPoi != null
                                    ? const Color(0xFFFF9B7A)
                                    : Colors.white.withValues(alpha: 0.08),
                                width: _selectedPoi != null ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _selectedPoi != null
                                        ? const Color(0xFFFF9B7A).withValues(alpha: 0.2)
                                        : Colors.white10,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    CupertinoIcons.compass_fill,
                                    color: _selectedPoi != null
                                        ? const Color(0xFFFF9B7A)
                                        : Colors.white54,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedPoi == null
                                            ? 'Select Campus POI / Target'
                                            : _selectedPoi!.name,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: _selectedPoi != null
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _selectedPoi == null
                                            ? 'Tap to search & pick navigation destination'
                                            : (_selectedPoi!.address.isNotEmpty
                                                ? _selectedPoi!.address
                                                : 'Navigation target set'),
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_selectedPoi != null)
                                  IconButton(
                                    icon: const Icon(CupertinoIcons.xmark_circle_fill,
                                        color: Colors.white54, size: 20),
                                    onPressed: () {
                                      setState(() {
                                        _selectedPoi = null;
                                        _locationController.text = '';
                                      });
                                    },
                                  )
                                else
                                  const Icon(CupertinoIcons.chevron_right,
                                      color: Colors.white38, size: 16),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        _buildSectionTitle('Location Details'),
                        const SizedBox(height: 16),
                        SleekTextField(
                          title: 'Location / Building',
                          controller: _locationController,
                          placeholder: 'Enter building/campus name',
                          icon: CupertinoIcons.location_solid,
                          readOnly: _selectedPoi != null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: SleekTextField(
                                title: 'Floor',
                                controller: _floorController,
                                placeholder: 'e.g. 2nd Floor',
                                icon: CupertinoIcons.layers_alt,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SleekTextField(
                                title: 'Room No',
                                controller: _roomNoController,
                                placeholder: 'e.g. Room 204',
                                icon: CupertinoIcons.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSectionTitle('Date', isRequired: true, hasValue: startDate != null),
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
                            _buildSectionTitle('Time', isRequired: true, hasValue: startTime != null),
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

                      ],

                      const SizedBox(height: 32),

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
                      const SizedBox(height: 100),
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
  final bool readOnly;

  const SleekTextField({
    super.key,
    required this.title,
    required this.controller,
    required this.placeholder,
    required this.icon,
    this.maxLines = 1,
    this.isRequired = false,
    this.maxLength,
    this.readOnly = false,
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
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                if (widget.isRequired) ...[
                  const SizedBox(width: 6),
                  widget.controller.text.trim().isNotEmpty
                      ? const Icon(CupertinoIcons.checkmark_alt_circle_fill, color: Colors.green, size: 16)
                      : const Icon(CupertinoIcons.check_mark_circled, color: Color(0xFFE63946), size: 16),
                ],
                if (widget.readOnly) ...[
                  const SizedBox(width: 6),
                  const Icon(CupertinoIcons.lock_fill, color: Colors.green, size: 14),
                ],
              ],
            ),
            if (widget.maxLength != null)
              Text(
                '${widget.controller.text.length} / ${widget.maxLength}',
                style: TextStyle(
                  color: widget.controller.text.length >= widget.maxLength! 
                    ? const Color(0xFFE63946) 
                    : Colors.white54,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: widget.readOnly ? const Color(0xFF161616) : const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.readOnly
                  ? Colors.green.withValues(alpha: 0.4)
                  : (_isFocused ? const Color(0xFFFF9B7A) : Colors.white.withValues(alpha: 0.05)),
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
                  color: widget.readOnly
                      ? Colors.green
                      : (_isFocused ? const Color(0xFFFF9B7A) : Colors.grey[500]),
                  size: 20,
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  readOnly: widget.readOnly,
                  maxLines: widget.maxLines,
                  maxLength: widget.maxLength,
                  style: TextStyle(
                    fontSize: 15,
                    color: widget.readOnly ? Colors.white70 : Colors.white,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
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
