import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../models/animal_model.dart';
import '../../../services/animal_service.dart';

class PetFormScreen extends StatefulWidget {
  final AnimalModel? animal;
  const PetFormScreen({super.key, this.animal});
  @override
  State<PetFormScreen> createState() => _PetFormScreenState();
}

class _PetFormScreenState extends State<PetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name, _breed, _age;
  String _species = 'ໝາ';
  bool _loading = false;

  XFile? _pickedImage;
  String? _existingPhotoUrl;

  bool get _isEdit => widget.animal != null;

  static const _speciesOptions = ['ໝາ', 'ແມວ', 'ນົກ', 'ກະຕ່າຍ', 'ປາ', 'ອື່ນໆ'];

  @override
  void initState() {
    super.initState();
    _name  = TextEditingController(text: widget.animal?.name  ?? '');
    _breed = TextEditingController(text: widget.animal?.breed ?? '');
    _age   = TextEditingController(text: widget.animal?.age?.toString() ?? '');
    _species = widget.animal?.species ?? 'ໝາ';
    if (!_speciesOptions.contains(_species)) _species = 'ອື່ນໆ';
    _existingPhotoUrl = widget.animal?.photoUrl;
  }

  @override
  void dispose() {
    _name.dispose();
    _breed.dispose();
    _age.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 75,
    );
    if (file != null && mounted) setState(() => _pickedImage = file);
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
            title: const Text('ຖ່າຍຮູບ'),
            onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
            title: const Text('ເລືອກຈາກ Gallery'),
            onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
          ),
          if (_pickedImage != null || _existingPhotoUrl != null)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('ລຶບຮູບ', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                setState(() { _pickedImage = null; _existingPhotoUrl = null; });
                Navigator.pop(context);
              },
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _loading) return;
    setState(() => _loading = true);
    try {
      final data = <String, dynamic>{
        'name':    _name.text.trim(),
        'species': _species,
        if (_breed.text.trim().isNotEmpty) 'breed': _breed.text.trim(),
        if (_age.text.isNotEmpty) 'age': int.tryParse(_age.text) ?? 0,
      };

      // ຖ້າເລືອກຮູບໃໝ່ → encode base64
      if (_pickedImage != null) {
        final bytes = await File(_pickedImage!.path).readAsBytes();
        final ext   = _pickedImage!.path.split('.').last.toLowerCase();
        final mime  = ext == 'png' ? 'image/png' : 'image/jpeg';
        data['photo_url'] = 'data:$mime;base64,${base64Encode(bytes)}';
      } else if (_existingPhotoUrl == null && _isEdit) {
        // ຜູ້ໃຊ້ລຶບຮູບ
        data['photo_url'] = '';
      }

      final Map<String, dynamic> res;
      if (_isEdit) {
        res = await AnimalService.update(widget.animal!.id, data);
      } else {
        res = await AnimalService.create(data);
      }
      if (!mounted) return;
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? (_isEdit ? 'ແກ້ໄຂສຳເລັດ' : 'ເພີ່ມສຳເລັດ'))));
        Navigator.pop(context, true);
      } else {
        _msg(res['message']?.toString() ?? 'ເກີດຂໍ້ຜິດພາດ');
      }
    } catch (_) {
      _msg('ບໍ່ສາມາດເຊື່ອມຕໍ່ເຊີບເວີ');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _msg(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  bool get _hasPhoto => _pickedImage != null || (_existingPhotoUrl != null && _existingPhotoUrl!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'ແກ້ໄຂຂໍ້ມູນສັດ' : 'ເພີ່ມສັດໃໝ່',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ─── ຮູບສັດ ────────────────────────────────────────────────
            Center(
              child: GestureDetector(
                onTap: _showPickerOptions,
                child: Stack(children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _hasPhoto
                            ? AppColors.primary.withOpacity(0.4)
                            : Colors.grey.shade200,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: _buildPhotoPreview(),
                    ),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                _hasPhoto ? 'ແຕະເພື່ອປ່ຽນຮູບ' : 'ແຕະເພື່ອເພີ່ມຮູບ',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),

            const SizedBox(height: 24),

            // ─── ຊື່ ──────────────────────────────────────────────────
            const Text('ຊື່ສັດ *',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _name,
              hintText: 'ຊື່ສັດລ້ຽງ',
              prefixIcon: Icons.pets,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'ກະລຸນາໃສ່ຊື່ສັດ' : null,
            ),

            const SizedBox(height: 18),
            const Text('ປະເພດສັດ *',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _species,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.inputField,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                prefixIcon: const Icon(Icons.category_outlined,
                    color: AppColors.textSecondary),
              ),
              items: _speciesOptions
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) { if (v != null) setState(() => _species = v); },
            ),

            const SizedBox(height: 18),
            const Text('ສາຍພັນ',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _breed,
              hintText: 'ສາຍພັນ (ບໍ່ບັງຄັບ)',
              prefixIcon: Icons.local_offer_outlined,
            ),

            const SizedBox(height: 18),
            const Text('ອາຍຸ (ປີ)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _age,
              hintText: 'ອາຍຸ (ບໍ່ບັງຄັບ)',
              prefixIcon: Icons.cake_outlined,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v != null && v.isNotEmpty && int.tryParse(v) == null) {
                  return 'ກະລຸນາໃສ່ຕົວເລກ';
                }
                return null;
              },
            ),

            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(
                        _isEdit ? 'ບັນທຶກການແກ້ໄຂ' : 'ເພີ່ມສັດ',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildPhotoPreview() {
    if (_pickedImage != null) {
      return Image.file(
        File(_pickedImage!.path),
        fit: BoxFit.cover,
        width: 110,
        height: 110,
      );
    }
    if (_existingPhotoUrl != null && _existingPhotoUrl!.isNotEmpty) {
      if (_existingPhotoUrl!.startsWith('data:image')) {
        final b64 = _existingPhotoUrl!.split(',').last;
        return Image.memory(
          base64Decode(b64),
          fit: BoxFit.cover,
          width: 110,
          height: 110,
        );
      }
    }
    return Center(
      child: Icon(Icons.pets, size: 48, color: AppColors.primary.withOpacity(0.4)),
    );
  }
}
