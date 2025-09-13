import 'package:flutter/material.dart';
import '../services/auth/password_validation_service.dart';
import '../config/app_theme.dart';

/// Widget que muestra la fortaleza de la contraseña en tiempo real
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  final bool showSuggestions;
  final VoidCallback? onValidationChanged;
  
  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    this.showSuggestions = true,
    this.onValidationChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final validation = PasswordValidationService.validatePassword(password);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Indicador de fortaleza
        _buildStrengthBar(validation),
        const SizedBox(height: 8),
        
        // Texto de fortaleza
        _buildStrengthText(validation),
        
        // Sugerencias si están habilitadas
        if (showSuggestions && validation.suggestions.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildSuggestions(validation.suggestions),
        ],
      ],
    );
  }
  
  Widget _buildStrengthBar(PasswordValidationResult validation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Barra de progreso
        Container(
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: AppTheme.borderColor,
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: validation.securityScore / 100,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                gradient: LinearGradient(
                  colors: _getStrengthColors(validation.strengthLevel),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        
        // Puntuación numérica
        Text(
          'Seguridad: ${validation.securityScore}%',
          style: TextStyle(
            fontSize: 12,
            color: _getStrengthColor(validation.strengthLevel),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  Widget _buildStrengthText(PasswordValidationResult validation) {
    return Row(
      children: [
        Icon(
          _getStrengthIcon(validation.strengthLevel),
          size: 16,
          color: _getStrengthColor(validation.strengthLevel),
        ),
        const SizedBox(width: 6),
        Text(
          validation.strengthText,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _getStrengthColor(validation.strengthLevel),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            validation.strengthDescription,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSuggestions(List<String> suggestions) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 16,
                color: Colors.blue.shade700,
              ),
              const SizedBox(width: 6),
              Text(
                'Sugerencias:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...suggestions.take(3).map((suggestion) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                  ),
                ),
                Expanded(
                  child: Text(
                    suggestion,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
  
  List<Color> _getStrengthColors(PasswordStrengthLevel level) {
    switch (level) {
      case PasswordStrengthLevel.veryWeak:
        return [Colors.red.shade400, Colors.red.shade600];
      case PasswordStrengthLevel.weak:
        return [Colors.orange.shade400, Colors.orange.shade600];
      case PasswordStrengthLevel.medium:
        return [Colors.yellow.shade400, Colors.yellow.shade600];
      case PasswordStrengthLevel.strong:
        return [Colors.lightGreen.shade400, Colors.lightGreen.shade600];
      case PasswordStrengthLevel.veryStrong:
        return [Colors.green.shade400, Colors.green.shade600];
    }
  }
  
  Color _getStrengthColor(PasswordStrengthLevel level) {
    switch (level) {
      case PasswordStrengthLevel.veryWeak:
        return Colors.red.shade600;
      case PasswordStrengthLevel.weak:
        return Colors.orange.shade600;
      case PasswordStrengthLevel.medium:
        return Colors.yellow.shade700;
      case PasswordStrengthLevel.strong:
        return Colors.lightGreen.shade600;
      case PasswordStrengthLevel.veryStrong:
        return Colors.green.shade600;
    }
  }
  
  IconData _getStrengthIcon(PasswordStrengthLevel level) {
    switch (level) {
      case PasswordStrengthLevel.veryWeak:
        return Icons.warning;
      case PasswordStrengthLevel.weak:
        return Icons.warning_amber;
      case PasswordStrengthLevel.medium:
        return Icons.info;
      case PasswordStrengthLevel.strong:
        return Icons.check_circle_outline;
      case PasswordStrengthLevel.veryStrong:
        return Icons.verified;
    }
  }
}
