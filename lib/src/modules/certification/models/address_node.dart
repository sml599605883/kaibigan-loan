import '../../../core/json/json.dart';

class AddressNode {
  const AddressNode({
    required this.addressId,
    required this.label,
    required this.children,
  });

  factory AddressNode.fromJson(Json json) {
    return AddressNode(
      addressId: json['cabdrivers'].stringValue.trim(),
      label: json['unwits'].stringValue.trim(),
      children: json['religiosities'].listValue
          .map(AddressNode.fromJson)
          .where((node) => node.label.isNotEmpty)
          .toList(growable: false),
    );
  }

  final String addressId;
  final String label;
  final List<AddressNode> children;
}
