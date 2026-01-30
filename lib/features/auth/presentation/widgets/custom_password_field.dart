import 'package:flutter/material.dart';

class CustomPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;

  const CustomPasswordField({
    super.key,
    required this.controller,
    required this.labelText,
  });

  @override
  State<CustomPasswordField> createState() => _CustomPasswordFieldState();
}

class _CustomPasswordFieldState extends State<CustomPasswordField> {
  bool _hidePassword = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _hidePassword,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.lock_outline),
        labelText: widget.labelText,
        suffixIcon: IconButton(
          icon: Icon(_hidePassword ? Icons.visibility_off : Icons.visibility),
          onPressed: () {
            setState(() {
              _hidePassword = !_hidePassword;
            });
          },
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
