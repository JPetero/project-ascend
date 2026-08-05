class EquipmentItem {
  const EquipmentItem({required this.type, this.customName});

  final String type;
  final String? customName;

  factory EquipmentItem.fromJson(Map<String, dynamic> json) {
    return EquipmentItem(
      type: json['type'] as String,
      customName: json['customName'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    if (customName != null) 'customName': customName,
  };
}
