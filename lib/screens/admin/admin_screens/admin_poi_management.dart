import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/poi_model.dart';
import '../../../services/poi_service.dart';
import '../../../services/shared_preferences_service.dart';
import '../../../config.dart';
import '../../../widgets/toast_manager.dart';
import '../../../widgets/custom_glass_dialog.dart';

class AdminPoiManagementScreen extends StatefulWidget {
  const AdminPoiManagementScreen({super.key});

  @override
  State<AdminPoiManagementScreen> createState() => _AdminPoiManagementScreenState();
}

class _AdminPoiManagementScreenState extends State<AdminPoiManagementScreen> {
  List<PoiModel> _pois = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchPOIs();
  }

  Future<void> _fetchPOIs() async {
    setState(() => _isLoading = true);
    try {
      final pois = await PoiService.getPOIs();
      setState(() {
        _pois = pois;
      });
    } catch (e) {
      debugPrint('Error fetching POIs: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<PoiModel> get _filteredPois {
    if (_searchQuery.trim().isEmpty) return _pois;
    final q = _searchQuery.toLowerCase();
    return _pois.where((p) {
      return p.name.toLowerCase().contains(q) || p.type.toLowerCase().contains(q);
    }).toList();
  }

  void _showPoiDialog({PoiModel? poi}) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => _PoiFormDialog(
        poi: poi,
        onSave: () {
          Navigator.pop(context);
          _fetchPOIs();
        },
      ),
    );
  }

  Future<void> _deletePoi(String id, String name) async {
    try {
      await PoiService.deletePOI(id);
      if (mounted) {
        EduMateToast.showCompact(context, message: '$name deleted', isSuccess: true);
      }
      _fetchPOIs();
    } catch (e) {
      if (mounted) {
        EduMateToast.showCompact(context, message: 'Failed to delete POI: $e', isSuccess: false);
      }
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'hotel':
        return const Color(0xFF3B82F6);
      case 'gardens':
        return const Color(0xFF10B981);
      case 'stadium':
        return const Color(0xFFF59E0B);
      case 'cafeteria':
        return const Color(0xFF8B5CF6);
      case 'campus':
      default:
        return const Color(0xFFDC2626); // Admin Red
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filteredPois;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Column(
                  children: [
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.08),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 16, right: 12),
                              child: Icon(
                                CupertinoIcons.search,
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                            Expanded(
                              child: CupertinoTextField(
                                placeholder: 'Search POIs by name or type...',
                                onChanged: (value) {
                                  setState(() {
                                    _searchQuery = value;
                                  });
                                },
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                  fontSize: 15,
                                ),
                                decoration: null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // POI List Body
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CupertinoActivityIndicator(radius: 14))
                          : filtered.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        CupertinoIcons.map_pin_slash,
                                        size: 48,
                                        color: isDark ? Colors.white30 : Colors.black26,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        _searchQuery.isNotEmpty
                                            ? 'No POIs found matching "$_searchQuery"'
                                            : 'No POIs configured yet',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDark ? Colors.white54 : Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                                  itemBuilder: (context, index) {
                                    return _buildPoiCard(filtered[index], isDark);
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Top Header Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF141414).withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.7),
                    border: Border(
                      bottom: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: SizedBox(
                      height: 50,
                      child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              child: Icon(
                                CupertinoIcons.back,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Text(
                              'POI Management',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Salena',
                                fontSize: 17,
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => _showPoiDialog(),
                              child: const Icon(
                                CupertinoIcons.add_circled_solid,
                                color: Color(0xFFDC2626), // Admin Red
                                size: 26,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoiCard(PoiModel poi, bool isDark) {
    final typeColor = _getTypeColor(poi.type);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF303030), Color(0xFF1A1A1A)]
              : const [Color(0xFFFFFFFF), Color(0xFFF3F4F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Line 1: Campus / POI Name
          Text(
            poi.name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),

          // Line 2: Campus Tag Text (below name)
          Text(
            poi.type,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: typeColor,
            ),
          ),
          const SizedBox(height: 6),

          // Line 3: Coordinates (below tag)
          Row(
            children: [
              Icon(CupertinoIcons.location_solid, size: 13, color: isDark ? Colors.white54 : Colors.black54),
              const SizedBox(width: 5),
              Text(
                '${poi.lat.toStringAsFixed(4)}, ${poi.lng.toStringAsFixed(4)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Line 4: Side by Side equal width Action Buttons
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context: context,
                  icon: CupertinoIcons.pencil_circle_fill,
                  label: 'Edit',
                  color: const Color(0xFFF59E0B), // Amber
                  isDark: isDark,
                  onTap: () => _showPoiDialog(poi: poi),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  context: context,
                  icon: CupertinoIcons.trash_fill,
                  label: 'Delete',
                  color: const Color(0xFFDC2626), // Admin Red
                  isDark: isDark,
                  onTap: () async {
                    final bool? confirm = await showDeleteConfirmationDialog(
                      context: context,
                      title: 'Delete POI',
                      description: 'Are you sure you want to delete "${poi.name}"?',
                    );
                    if (confirm == true) {
                      _deletePoi(poi.id, poi.name);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.25 : 0.15),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PoiFormDialog extends StatefulWidget {
  final PoiModel? poi;
  final VoidCallback onSave;

  const _PoiFormDialog({this.poi, required this.onSave});

  @override
  State<_PoiFormDialog> createState() => _PoiFormDialogState();
}

class _PoiFormDialogState extends State<_PoiFormDialog> {
  final _nameController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _descController = TextEditingController();

  File? _selectedImage;
  String _imageUrl = '';
  String _selectedType = 'Campus';
  bool _isSaving = false;

  final List<String> _types = ['Campus', 'Hotel', 'Gardens', 'Stadium', 'Cafeteria'];

  @override
  void initState() {
    super.initState();
    if (widget.poi != null) {
      _nameController.text = widget.poi!.name;
      _latController.text = widget.poi!.lat.toString();
      _lngController.text = widget.poi!.lng.toString();
      _descController.text = widget.poi!.description;
      _imageUrl = widget.poi!.imageUrl;
      _selectedType = widget.poi!.type;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final latStr = _latController.text.trim();
    final lngStr = _lngController.text.trim();
    final desc = _descController.text.trim();

    if (name.isEmpty || latStr.isEmpty || lngStr.isEmpty) {
      EduMateToast.showCompact(context, message: 'Please enter Name, Lat, and Lng', isSuccess: false);
      return;
    }

    final lat = double.tryParse(latStr);
    final lng = double.tryParse(lngStr);

    if (lat == null || lng == null) {
      EduMateToast.showCompact(context, message: 'Invalid latitude or longitude', isSuccess: false);
      return;
    }

    setState(() => _isSaving = true);

    try {
      String imageUrl = _imageUrl;
      if (_selectedImage != null) {
        final token = await SharedPreferencesService.getToken();
        final req = http.MultipartRequest('POST', Uri.parse('${Config.BASE_URL}/api/poi/upload-image'));
        if (token != null) req.headers['Authorization'] = 'Bearer $token';

        req.files.add(await http.MultipartFile.fromPath('image', _selectedImage!.path));
        final res = await req.send();
        final resBody = await res.stream.bytesToString();
        final data = jsonDecode(resBody);

        if (data['success'] == true) {
          imageUrl = data['imageUrl'];
        }
      }

      final poiModel = PoiModel(
        id: widget.poi?.id ?? '',
        name: name,
        lat: lat,
        lng: lng,
        type: _selectedType,
        description: desc,
        imageUrl: imageUrl,
      );

      if (widget.poi == null) {
        await PoiService.createPOI(poiModel);
        if (mounted) {
          EduMateToast.showCompact(context, message: 'POI created successfully', isSuccess: true);
        }
      } else {
        await PoiService.updatePOI(poiModel);
        if (mounted) {
          EduMateToast.showCompact(context, message: 'POI updated successfully', isSuccess: true);
        }
      }

      widget.onSave();
    } catch (e) {
      if (mounted) {
        EduMateToast.showCompact(context, message: 'Failed to save POI: $e', isSuccess: false);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Modal Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.poi == null ? 'New POI' : 'Edit POI',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const CupertinoActivityIndicator()
                    : const Text(
                        'Save',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFDC2626), // Admin Red
                        ),
                      ),
              ),
            ],
          ),
          const Divider(),

          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                const SizedBox(height: 12),
                // Name
                CupertinoTextField(
                  controller: _nameController,
                  placeholder: 'POI Name (e.g. Campus 15 Library)',
                  padding: const EdgeInsets.all(14),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 14),

                // Coordinates Row
                Row(
                  children: [
                    Expanded(
                      child: CupertinoTextField(
                        controller: _latController,
                        placeholder: 'Latitude (20.3530)',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        padding: const EdgeInsets.all(14),
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CupertinoTextField(
                        controller: _lngController,
                        placeholder: 'Longitude (85.8182)',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        padding: const EdgeInsets.all(14),
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Description
                CupertinoTextField(
                  controller: _descController,
                  placeholder: 'Description...',
                  padding: const EdgeInsets.all(14),
                  maxLines: 4,
                  maxLength: 400,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 14),

                // Image Picker Container
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 130,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08),
                      ),
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(_selectedImage!, fit: BoxFit.cover, width: double.infinity),
                          )
                        : (_imageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(_imageUrl, fit: BoxFit.cover, width: double.infinity),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(CupertinoIcons.camera_fill, size: 32, color: Color(0xFFDC2626)),
                                  SizedBox(height: 8),
                                  Text(
                                    'Tap to upload POI image',
                                    style: TextStyle(fontSize: 13, color: Colors.white60),
                                  ),
                                ],
                              )),
                  ),
                ),
                const SizedBox(height: 18),

                // Type Picker Header
                Text(
                  'POI Category Type',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: CupertinoPicker(
                    itemExtent: 34,
                    scrollController: FixedExtentScrollController(
                      initialItem: _types.contains(_selectedType) ? _types.indexOf(_selectedType) : 0,
                    ),
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _selectedType = _types[index];
                      });
                    },
                    children: _types.map((t) {
                      return Center(
                        child: Text(
                          t,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
