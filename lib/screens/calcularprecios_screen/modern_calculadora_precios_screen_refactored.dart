import 'package:flutter/material.dart';
import '../../widgets/ui/calculadora/calculadora_precios_widget.dart';

/// Pantalla de calculadora de precios con nueva implementación completa
class ModernCalculadoraPreciosScreenRefactored extends StatelessWidget {
  final bool showCloseButton;
  
  const ModernCalculadoraPreciosScreenRefactored({
    super.key,
    this.showCloseButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return CalculadoraPreciosWidget(
      showCloseButton: showCloseButton,
      onClose: () => Navigator.of(context).pop(),
    );
  }
}

