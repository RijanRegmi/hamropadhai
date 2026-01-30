import 'package:flutter/material.dart';

class GenderSelector extends StatelessWidget {
  final String selectedGender;
  final ValueChanged<String> onGenderChanged;

  const GenderSelector({
    super.key,
    required this.selectedGender,
    required this.onGenderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: RadioListTile<String>(
              title: const Text("Male"),
              value: "male",
              groupValue: selectedGender,
              onChanged: (value) {
                if (value != null) {
                  onGenderChanged(value);
                }
              },
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
          Expanded(
            child: RadioListTile<String>(
              title: const Text("Female"),
              value: "female",
              groupValue: selectedGender,
              onChanged: (value) {
                if (value != null) {
                  onGenderChanged(value);
                }
              },
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ],
      ),
    );
  }
}
