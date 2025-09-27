import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../models/talla.dart';
import '../forms/size_form_widget.dart';

class SizeFormModal extends StatelessWidget {
  final Talla? size;
  final Function(Talla) onSizeCreated;
  final Function(Talla) onSizeUpdated;

  const SizeFormModal({
    super.key,
    this.size,
    required this.onSizeCreated,
    required this.onSizeUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.5,
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SizeFormWidget(
                size: size,
                onSave: (savedSize) {
                  if (size == null) {
                    onSizeCreated(savedSize);
                  } else {
                    onSizeUpdated(savedSize);
                  }
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            size == null ? 'Nueva Talla' : 'Editar Talla',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}