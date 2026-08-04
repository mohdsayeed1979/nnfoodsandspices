import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/storage/hive_service.dart';
import '../../domain/address.dart';

Address _fromMap(Map map) => Address(
      id: map['id'] as String,
      fullName: map['fullName'] as String,
      phone: map['phone'] as String,
      line1: map['line1'] as String,
      line2: map['line2'] as String?,
      city: map['city'] as String,
      state: map['state'] as String,
      pincode: map['pincode'] as String,
      isDefault: map['isDefault'] as bool? ?? false,
    );

Map<String, dynamic> _toMap(Address a) => {
      'id': a.id,
      'fullName': a.fullName,
      'phone': a.phone,
      'line1': a.line1,
      'line2': a.line2,
      'city': a.city,
      'state': a.state,
      'pincode': a.pincode,
      'isDefault': a.isDefault,
    };

class AddressNotifier extends StateNotifier<List<Address>> {
  AddressNotifier() : super(_readFromBox());

  Box<Map> get _box => Hive.box<Map>(HiveBoxes.addresses);

  static List<Address> _readFromBox() {
    final box = Hive.box<Map>(HiveBoxes.addresses);
    return box.values.map(_fromMap).toList();
  }

  Future<Address> add({
    required String fullName,
    required String phone,
    required String line1,
    String? line2,
    required String city,
    required String state,
    required String pincode,
  }) async {
    final isFirst = _box.isEmpty;
    final address = Address(
      id: const Uuid().v4(),
      fullName: fullName,
      phone: phone,
      line1: line1,
      line2: line2,
      city: city,
      state: state,
      pincode: pincode,
      isDefault: isFirst,
    );
    await _box.put(address.id, _toMap(address));
    this.state = _readFromBox();
    return address;
  }

  Future<void> remove(String id) async {
    await _box.delete(id);
    state = _readFromBox();
  }

  Future<void> setDefault(String id) async {
    for (final entry in _box.toMap().entries) {
      final address = _fromMap(entry.value);
      await _box.put(entry.key, _toMap(address.copyWith(isDefault: entry.key == id)));
    }
    state = _readFromBox();
  }
}

final addressNotifierProvider = StateNotifierProvider<AddressNotifier, List<Address>>((ref) {
  return AddressNotifier();
});

final defaultAddressProvider = Provider<Address?>((ref) {
  final addresses = ref.watch(addressNotifierProvider);
  if (addresses.isEmpty) return null;
  return addresses.firstWhere((a) => a.isDefault, orElse: () => addresses.first);
});
