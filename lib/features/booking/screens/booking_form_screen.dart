import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/animal_model.dart';
import '../../../models/service_model.dart';
import '../../../services/animal_service.dart';
import '../../../services/booking_service.dart';
import '../../../services/service_service.dart';
import 'deposit_payment_screen.dart';

const int _kDepositAmount = 50;

// ─── Fixed time slot constants ────────────────────────────────────────────────
const _kMorningSlots   = ['09:00', '09:36', '10:12', '10:48', '11:24'];
const _kAfternoonSlots = ['13:00', '13:36', '14:12', '14:48', '15:24'];

class BookingFormScreen extends StatefulWidget {
  final ServiceModel? preSelectedService;
  final AnimalModel?  preSelectedAnimal;
  const BookingFormScreen({super.key, this.preSelectedService, this.preSelectedAnimal});
  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _noteCtrl = TextEditingController();

  List<AnimalModel>  _animals  = [];
  List<ServiceModel> _services = [];
  AnimalModel?       _animal;
  ServiceModel?      _service;
  DateTime?          _date;
  String?            _scheduledTime;

  // availability: { 'morning': [{'time':'09:00','available':true}, ...], 'afternoon': [...] }
  Map<String, dynamic>? _availability;
  bool _loading = false, _dataLoading = true, _availLoading = false;

  @override
  void initState() {
    super.initState();
    _service = widget.preSelectedService;
    _animal  = widget.preSelectedAnimal;
    _loadData();
  }

  @override
  void dispose() { _noteCtrl.dispose(); super.dispose(); }

  Future<void> _loadData() async {
    try {
      final r = await Future.wait([AnimalService.getAll(), ServiceService.getAll()]);
      if (!mounted) return;
      setState(() {
        _animals  = ((r[0]['data'] as List?) ?? []).map((e) => AnimalModel.fromJson(e)).toList();
        _services = ((r[1]['data'] as List?) ?? []).map((e) => ServiceModel.fromJson(e)).toList();
        if (_animal  != null) { final m = _animals.where((a) => a.id == _animal!.id).toList();   if (m.isNotEmpty) _animal  = m.first; }
        if (_service != null) { final m = _services.where((s) => s.id == _service!.id).toList(); if (m.isNotEmpty) _service = m.first; }
        _dataLoading = false;
      });
    } catch (_) { if (mounted) setState(() => _dataLoading = false); }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate:   DateTime.now().add(const Duration(days: 1)),
      lastDate:    DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (d != null) {
      setState(() { _date = d; _scheduledTime = null; _availability = null; });
      _loadAvailability(d);
    }
  }

  Future<void> _loadAvailability(DateTime date) async {
    setState(() => _availLoading = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final res = await BookingService.getAvailability(dateStr);
      if (!mounted) return;
      if (res['success'] == true) {
        setState(() => _availability = res['data'] as Map<String, dynamic>?);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _availLoading = false);
    }
  }

  bool _isTimeTaken(String time) {
    if (_availability == null) return false;
    final isMorning = _kMorningSlots.contains(time);
    final list = (_availability![isMorning ? 'morning' : 'afternoon'] as List?) ?? [];
    for (final e in list) {
      if (e['time'] == time) return e['available'] == false;
    }
    return false;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _loading) return;
    if (_animal        == null) { _msg('ກະລຸນາເລືອກສັດລ້ຽງ');     return; }
    if (_service       == null) { _msg('ກະລຸນາເລືອກບໍລິການ');      return; }
    if (_date          == null) { _msg('ກະລຸນາເລືອກວັນທີນັດ');     return; }
    if (_scheduledTime == null) { _msg('ກະລຸນາເລືອກຄິວເວລາ');      return; }

    setState(() => _loading = true);
    try {
      final res = await BookingService.create({
        'animal_id':      _animal!.id,
        'service_id':     _service!.id,
        'scheduled_date': DateFormat('yyyy-MM-dd').format(_date!),
        'scheduled_time': _scheduledTime,
        if (_noteCtrl.text.trim().isNotEmpty) 'note': _noteCtrl.text.trim(),
      });
      if (!mounted) return;
      if (res['success'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DepositPaymentScreen(
              bookingId:    res['id'] as int,
              servicePrice: _service!.price,
              expiresAt:    res['expires_at'] as String?,
            ),
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ສ້າງການຈອງ', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _dataLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  // No pets warning
                  if (_animals.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: const Row(children: [
                        Icon(Icons.info_outline, color: Colors.orange, size: 18),
                        SizedBox(width: 8),
                        Expanded(child: Text('ກະລຸນາເພີ່ມສັດລ້ຽງໃນ "ສັດລ້ຽງ" ກ່ອນ',
                            style: TextStyle(color: Colors.orange, fontSize: 13))),
                      ]),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Animal
                  _label('ສັດລ້ຽງ *'),
                  DropdownButtonFormField<AnimalModel>(
                    value: _animal,
                    hint: const Text('ເລືອກສັດລ້ຽງ'),
                    decoration: _drop(Icons.pets),
                    items: _animals.map((a) => DropdownMenuItem(value: a, child: Text(a.name))).toList(),
                    onChanged: (v) => setState(() => _animal = v),
                    validator: (v) => v == null ? 'ກະລຸນາເລືອກສັດລ້ຽງ' : null,
                  ),

                  const SizedBox(height: 18),
                  _label('ບໍລິການ *'),
                  DropdownButtonFormField<ServiceModel>(
                    value: _service,
                    hint: const Text('ເລືອກບໍລິການ'),
                    decoration: _drop(Icons.medical_services_outlined),
                    items: _services.map((s) => DropdownMenuItem(
                      value: s,
                      child: Text('${s.name}  (${NumberFormat('#,##0').format(s.price)} ₭)'),
                    )).toList(),
                    onChanged: (v) => setState(() => _service = v),
                    validator: (v) => v == null ? 'ກະລຸນາເລືອກບໍລິການ' : null,
                  ),

                  // Price summary
                  if (_service != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primary.withOpacity(0.18)),
                      ),
                      child: Column(children: [
                        _PriceRow(label: 'ລາຄາລວມ',
                            value: '${NumberFormat('#,##0').format(_service!.price)} ກີບ',
                            icon: Icons.monetization_on_outlined),
                        const Divider(height: 14, thickness: 0.6),
                        _PriceRow(label: 'ຄ່າມັດຈຳ (ຊຳລະຕອນຈອງ)',
                            value: '${NumberFormat('#,##0').format(_kDepositAmount)} ກີບ',
                            icon: Icons.account_balance_wallet_outlined,
                            highlight: true),
                        const SizedBox(height: 6),
                        _PriceRow(label: 'ຍອດທີ່ຍັງເຫຼືອ (ຊຳລະທີຫຼັງ)',
                            value: '${NumberFormat('#,##0').format(_service!.price - _kDepositAmount)} ກີບ',
                            icon: Icons.payments_outlined),
                      ]),
                    ),
                  ],

                  // Date
                  const SizedBox(height: 18),
                  _label('ວັນທີນັດ *'),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                      decoration: BoxDecoration(
                        color: AppColors.inputField,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        const Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.textSecondary),
                        const SizedBox(width: 12),
                        Text(
                          _date == null ? 'ເລືອກວັນທີ' : DateFormat('dd/MM/yyyy').format(_date!),
                          style: TextStyle(
                            fontSize: 14,
                            color: _date == null ? AppColors.textSecondary : AppColors.textMain,
                          ),
                        ),
                      ]),
                    ),
                  ),

                  // ─── Time slot picker ────────────────────────────────────
                  const SizedBox(height: 20),
                  _label('ເລືອກຄິວເວລາ *'),

                  if (_date == null)
                    _hintBox('ກະລຸນາເລືອກວັນທີກ່ອນ ແລ້ວຈຶ່ງເລືອກຄິວເວລາໄດ້')
                  else if (_availLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      )),
                    )
                  else ...[
                    _SlotGroup(
                      label: '🌅 ຕອນເຊົ້າ',
                      sublabel: '09:00 – 12:00',
                      times: _kMorningSlots,
                      selected: _scheduledTime,
                      isTaken: _isTimeTaken,
                      onSelect: (t) => setState(() => _scheduledTime = t),
                    ),
                    const SizedBox(height: 16),
                    _SlotGroup(
                      label: '🌇 ຕອນບ່າຍ',
                      sublabel: '13:00 – 16:00',
                      times: _kAfternoonSlots,
                      selected: _scheduledTime,
                      isTaken: _isTimeTaken,
                      onSelect: (t) => setState(() => _scheduledTime = t),
                    ),
                  ],

                  // Note
                  const SizedBox(height: 18),
                  _label('ໝາຍເຫດ'),
                  TextFormField(
                    controller: _noteCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'ໝາຍເຫດ (ບໍ່ບັງຄັບ)',
                      hintStyle: const TextStyle(color: AppColors.textHint),
                      prefixIcon: const Icon(Icons.notes_outlined, color: AppColors.textSecondary),
                      filled: true, fillColor: AppColors.inputField,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: (_loading || _animals.isEmpty) ? null : _submit,
                      icon: _loading
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.qr_code_2_outlined),
                      label: const Text('ຢືນຢັນ ແລະ ຊຳລະມັດຈຳ',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ]),
              ),
            ),
    );
  }

  Widget _hintBox(String text) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Row(children: [
      const Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
      const SizedBox(width: 8),
      Expanded(child: Text(text,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
    ]),
  );

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
  );

  InputDecoration _drop(IconData icon) => InputDecoration(
    filled: true, fillColor: AppColors.inputField,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    prefixIcon: Icon(icon, color: AppColors.textSecondary),
  );
}

// ─── Slot Group (morning / afternoon) ────────────────────────────────────────

class _SlotGroup extends StatelessWidget {
  final String label, sublabel;
  final List<String> times;
  final String? selected;
  final bool Function(String) isTaken;
  final void Function(String) onSelect;

  const _SlotGroup({
    required this.label,
    required this.sublabel,
    required this.times,
    required this.selected,
    required this.isTaken,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(width: 6),
          Text(sublabel, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ]),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: times.map((time) {
            final taken    = isTaken(time);
            final isSelected = selected == time;
            return _TimeChip(
              time: time,
              taken: taken,
              selected: isSelected,
              onTap: taken ? null : () => onSelect(time),
            );
          }).toList(),
        ),
      ]),
    );
  }
}

// ─── Time Chip ────────────────────────────────────────────────────────────────

class _TimeChip extends StatelessWidget {
  final String time;
  final bool taken, selected;
  final VoidCallback? onTap;

  const _TimeChip({
    required this.time,
    required this.taken,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg, border, text;
    if (taken) {
      bg = Colors.grey.shade100; border = Colors.grey.shade300; text = Colors.grey.shade400;
    } else if (selected) {
      bg = AppColors.primary.withOpacity(0.10); border = AppColors.primary; text = AppColors.primary;
    } else {
      bg = Colors.grey.shade50; border = Colors.grey.shade200; text = AppColors.textMain;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border, width: selected ? 2 : 1.2),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            time,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: text,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            taken ? 'ເຕັມ' : selected ? '✓ ເລືອກແລ້ວ' : 'ວ່າງ',
            style: TextStyle(fontSize: 10, color: text, fontWeight: FontWeight.w500),
          ),
        ]),
      ),
    );
  }
}

// ─── Price Row ────────────────────────────────────────────────────────────────

class _PriceRow extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final bool highlight;
  const _PriceRow({required this.label, required this.value, required this.icon, this.highlight = false});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 15, color: highlight ? AppColors.primary : AppColors.textSecondary),
    const SizedBox(width: 6),
    Expanded(child: Text(label, style: TextStyle(fontSize: 13,
        color: highlight ? AppColors.textMain : AppColors.textSecondary))),
    Text(value, style: TextStyle(fontSize: 13,
        fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
        color: highlight ? AppColors.primary : AppColors.textMain)),
  ]);
}
