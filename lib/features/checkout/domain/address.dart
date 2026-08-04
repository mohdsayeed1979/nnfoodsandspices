import 'package:freezed_annotation/freezed_annotation.dart';

part 'address.freezed.dart';
part 'address.g.dart';

@freezed
abstract class Address with _$Address {
  const factory Address({
    required String id,
    required String fullName,
    required String phone,
    required String line1,
    String? line2,
    required String city,
    required String state,
    required String pincode,
    @Default(false) bool isDefault,
  }) = _Address;

  const Address._();

  String get formatted => '$line1${line2 != null && line2!.isNotEmpty ? ', $line2' : ''}, $city, $state - $pincode';

  factory Address.fromJson(Map<String, dynamic> json) => _$AddressFromJson(json);
}
