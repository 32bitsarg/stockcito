import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class ValidatedTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool obscureText;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final VoidCallback? onChanged;

  const ValidatedTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.keyboardType,
    this.validator,
    this.obscureText = false,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.onChanged,
  });

  @override
  State<ValidatedTextField> createState() => _ValidatedTextFieldState();
}

class _ValidatedTextFieldState extends State<ValidatedTextField> {
  bool _isValid = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_validateField);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_validateField);
    super.dispose();
  }

  void _validateField() {
    if (widget.validator != null) {
      final error = widget.validator!(widget.controller.text);
      setState(() {
        _isValid = error == null;
        _errorMessage = error;
      });
    }
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: widget.obscureText,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          enabled: widget.enabled,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            prefixIcon: widget.icon != null
                ? Icon(
                    widget.icon,
                    color: _isValid ? AppTheme.primaryColor : AppTheme.errorColor,
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _isValid ? AppTheme.borderColor : AppTheme.errorColor,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _isValid ? AppTheme.borderColor : AppTheme.errorColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _isValid ? AppTheme.primaryColor : AppTheme.errorColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppTheme.errorColor,
                width: 2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppTheme.errorColor,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: widget.enabled ? Colors.white : AppTheme.backgroundColor,
            errorText: _errorMessage,
            errorStyle: const TextStyle(
              color: AppTheme.errorColor,
              fontSize: 12,
            ),
          ),
          validator: widget.validator,
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: AppTheme.errorColor,
                size: 16,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: AppTheme.errorColor,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class ValidatedDropdownField<T> extends StatefulWidget {
  final T? value;
  final String label;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;
  final bool enabled;
  final IconData? icon;

  const ValidatedDropdownField({
    super.key,
    this.value,
    required this.label,
    required this.items,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.icon,
  });

  @override
  State<ValidatedDropdownField<T>> createState() => _ValidatedDropdownFieldState<T>();
}

class _ValidatedDropdownFieldState<T> extends State<ValidatedDropdownField<T>> {
  bool _isValid = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _validateField();
  }

  void _validateField() {
    if (widget.validator != null) {
      final error = widget.validator!(widget.value);
      setState(() {
        _isValid = error == null;
        _errorMessage = error;
      });
    }
  }

  @override
  void didUpdateWidget(ValidatedDropdownField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _validateField();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<T>(
          value: widget.value,
          items: widget.items,
          onChanged: widget.enabled ? (value) {
            widget.onChanged?.call(value);
            _validateField();
          } : null,
          decoration: InputDecoration(
            labelText: widget.label,
            prefixIcon: widget.icon != null
                ? Icon(
                    widget.icon,
                    color: _isValid ? AppTheme.primaryColor : AppTheme.errorColor,
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _isValid ? AppTheme.borderColor : AppTheme.errorColor,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _isValid ? AppTheme.borderColor : AppTheme.errorColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _isValid ? AppTheme.primaryColor : AppTheme.errorColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppTheme.errorColor,
                width: 2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppTheme.errorColor,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: widget.enabled ? Colors.white : AppTheme.backgroundColor,
            errorText: _errorMessage,
            errorStyle: const TextStyle(
              color: AppTheme.errorColor,
              fontSize: 12,
            ),
          ),
          validator: widget.validator,
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: AppTheme.errorColor,
                size: 16,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: AppTheme.errorColor,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
