import '../../../core/json/json.dart';
import 'address_node.dart';

class AddressOption extends AddressNode {
  const AddressOption({
    required super.addressId,
    required super.label,
    required super.children,
  });

  factory AddressOption.fromJson(Json json) {
    final node = AddressNode.fromJson(json);
    return AddressOption(
      addressId: node.addressId,
      label: node.label,
      children: node.children,
    );
  }

  static List<AddressOption> parseList(Json states) {
    return states['religiosities'].listValue
        .map(AddressOption.fromJson)
        .where((option) => option.label.isNotEmpty)
        .toList(growable: false);
  }
}
