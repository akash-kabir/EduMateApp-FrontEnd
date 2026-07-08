import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/poi_model.dart';
import '../../../services/poi_service.dart';
import '../../../services/shared_preferences_service.dart';
import '../../../config.dart';

class AdminPoiManagementScreen extends StatefulWidget {
  const AdminPoiManagementScreen({super.key});

  @override
  State<AdminPoiManagementScreen> createState() => _AdminPoiManagementScreenState();
}

class _AdminPoiManagementScreenState extends State<AdminPoiManagementScreen> {
  List<PoiModel> _pois = [];
  bool _isLoading = true;

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

  Future<void> _deletePoi(String id) async {
    try {
      await PoiService.deletePOI(id);
      _fetchPOIs();
    } catch (e) {
      debugPrint('Error deleting POI: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? CupertinoColors.black : CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark ? CupertinoColors.black : CupertinoColors.white,
        middle: const Text('POI Management'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.add),
          onPressed: () => _showPoiDialog(),
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _pois.isEmpty
                ? const Center(child: Text('No POIs found. Add some!'))
                : ListView.builder(
                    itemCount: _pois.length,
                    itemBuilder: (context, index) {
                      final poi = _pois[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? CupertinoColors.darkBackgroundGray : CupertinoColors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: CupertinoListTile(
                          title: Text(poi.name),
                          subtitle: Text('${poi.type} • ${poi.lat.toStringAsFixed(4)}, ${poi.lng.toStringAsFixed(4)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () => _showPoiDialog(poi: poi),
                                child: const Icon(CupertinoIcons.pencil, size: 20),
                              ),
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  showCupertinoDialog(
                                    context: context,
                                    builder: (ctx) => CupertinoAlertDialog(
                                      title: const Text('Delete POI?'),
                                      content: Text('Are you sure you want to delete ${poi.name}?'),
                                      actions: [
                                        CupertinoDialogAction(
                                          child: const Text('Cancel'),
                                          onPressed: () => Navigator.pop(ctx),
                                        ),
                                        CupertinoDialogAction(
                                          isDestructiveAction: true,
                                          child: const Text('Delete'),
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            _deletePoi(poi.id);
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: const Icon(CupertinoIcons.delete, size: 20, color: CupertinoColors.destructiveRed),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final latStr = _latController.text.trim();
    final lngStr = _lngController.text.trim();

    if (name.isEmpty || latStr.isEmpty || lngStr.isEmpty) {
      // Basic validation
      return;
    }

    final lat = double.tryParse(latStr) ?? 0.0;
    final lng = double.tryParse(lngStr) ?? 0.0;

    setState(() => _isSaving = true);

    try {
      String finalImageUrl = _imageUrl;

      // Upload image to Cloudinary if a new one is selected
      if (_selectedImage != null) {
        final token = await SharedPreferencesService.getToken();
        final sigResponse = await http.get(
          Uri.parse('${Config.BASE_URL}/api/upload/signature'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (sigResponse.statusCode == 200) {
          final sigData = jsonDecode(sigResponse.body);
          final cloudName = sigData['cloudName'];
          
          final uploadRequest = http.MultipartRequest(
            'POST',
            Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload'),
          );
          uploadRequest.fields['signature'] = sigData['signature'];
          uploadRequest.fields['api_key'] = sigData['apiKey'];
          uploadRequest.fields['timestamp'] = sigData['timestamp'].toString();
          uploadRequest.fields['folder'] = sigData['folder'];
          uploadRequest.fields['transformation'] = sigData['transformation'];
          uploadRequest.files.add(
            await http.MultipartFile.fromPath('file', _selectedImage!.path),
          );

          final streamedResponse = await uploadRequest.send();
          final response = await http.Response.fromStream(streamedResponse);

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            finalImageUrl = data['secure_url'];
          }
        }
      }

      final poi = PoiModel(
        id: widget.poi?.id ?? '',
        name: name,
        lat: lat,
        lng: lng,
        description: _descController.text.trim(),
        address: '',
        imageUrl: finalImageUrl,
        type: _selectedType,
      );

      if (widget.poi == null) {
        await PoiService.createPOI(poi);
      } else {
        await PoiService.updatePOI(poi);
      }
      widget.onSave();
    } catch (e) {
      debugPrint('Error saving POI: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? CupertinoColors.black : CupertinoColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(widget.poi == null ? 'New POI' : 'Edit POI', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                CupertinoButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving ? const CupertinoActivityIndicator() : const Text('Save'),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                children: [
                  CupertinoTextField(controller: _nameController, placeholder: 'POI Name', padding: const EdgeInsets.all(12)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: CupertinoTextField(controller: _latController, placeholder: 'Latitude (e.g. 20.2961)', padding: const EdgeInsets.all(12), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                      const SizedBox(width: 12),
                      Expanded(child: CupertinoTextField(controller: _lngController, placeholder: 'Longitude (e.g. 85.8245)', padding: const EdgeInsets.all(12), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CupertinoTextField(controller: _descController, placeholder: 'Description (max 400 chars)', padding: const EdgeInsets.all(12), maxLines: 8, maxLength: 400),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? CupertinoColors.darkBackgroundGray : CupertinoColors.systemGrey6,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: CupertinoColors.systemGrey4),
                      ),
                      child: _selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(_selectedImage!, fit: BoxFit.cover),
                            )
                          : (_imageUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(_imageUrl, fit: BoxFit.cover),
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(CupertinoIcons.camera, size: 32, color: CupertinoColors.systemGrey),
                                    SizedBox(height: 8),
                                    Text('Tap to pick an image', style: TextStyle(color: CupertinoColors.systemGrey)),
                                  ],
                                )),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 150,
                    child: CupertinoPicker(
                      itemExtent: 32,
                      scrollController: FixedExtentScrollController(initialItem: _types.contains(_selectedType) ? _types.indexOf(_selectedType) : 0),
                      onSelectedItemChanged: (index) {
                        setState(() {
                          _selectedType = _types[index];
                        });
                      },
                      children: _types.map((t) => Center(child: Text(t))).toList(),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
