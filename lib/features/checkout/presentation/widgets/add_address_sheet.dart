import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/address_provider.dart';

class AddAddressSheet extends ConsumerStatefulWidget {
  const AddAddressSheet({super.key});

  @override
  ConsumerState<AddAddressSheet> createState() => _AddAddressSheetState();
}

class _AddAddressSheetState extends ConsumerState<AddAddressSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _line1 = TextEditingController();
  final _line2 = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _pincode = TextEditingController();

  @override
  void dispose() {
    for (final c in [_name, _phone, _line1, _line2, _city, _state, _pincode]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Add Delivery Address', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              _field(_name, 'Full Name'),
              _field(_phone, 'Phone Number', keyboardType: TextInputType.phone),
              _field(_line1, 'Address Line 1'),
              _field(_line2, 'Address Line 2 (optional)', required: false),
              Row(
                children: [
                  Expanded(child: _field(_city, 'City')),
                  const SizedBox(width: 10),
                  Expanded(child: _field(_state, 'State')),
                ],
              ),
              _field(_pincode, 'Pincode', keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    final address = await ref.read(addressNotifierProvider.notifier).add(
                          fullName: _name.text.trim(),
                          phone: _phone.text.trim(),
                          line1: _line1.text.trim(),
                          line2: _line2.text.trim().isEmpty ? null : _line2.text.trim(),
                          city: _city.text.trim(),
                          state: _state.text.trim(),
                          pincode: _pincode.text.trim(),
                        );
                    if (context.mounted) Navigator.of(context).pop(address);
                  },
                  child: const Text('Save Address'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, {TextInputType? keyboardType, bool required = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label, isDense: true),
        validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
      ),
    );
  }
}
