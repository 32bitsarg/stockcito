import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Widget que muestra los requisitos de contraseña con checkmarks visuales
class PasswordRequirementsValidator extends StatefulWidget {
  final String password;
  final bool showSuggestions;
  
  const PasswordRequirementsValidator({
    super.key,
    required this.password,
    this.showSuggestions = true,
  });

  @override
  State<PasswordRequirementsValidator> createState() => _PasswordRequirementsValidatorState();
}

class _PasswordRequirementsValidatorState extends State<PasswordRequirementsValidator>
    with TickerProviderStateMixin {
  
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _animations;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }
  
  void _initializeAnimations() {
    _animationControllers = List.generate(
      5, // 5 requisitos
      (index) => AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      ),
    );
    
    _animations = _animationControllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
    }).toList();
  }
  
  @override
  void dispose() {
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }
  
  @override
  void didUpdateWidget(PasswordRequirementsValidator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.password != widget.password) {
      _updateAnimations();
    }
  }
  
  void _updateAnimations() {
    final requirements = _getPasswordRequirements();
    
    for (int i = 0; i < requirements.length; i++) {
      if (requirements[i].isValid) {
        _animationControllers[i].forward();
      } else {
        _animationControllers[i].reverse();
      }
    }
  }
  
  List<PasswordRequirement> _getPasswordRequirements() {
    final password = widget.password;
    
    return [
      PasswordRequirement(
        text: '8+ chars',
        isValid: password.length >= 8,
        icon: Icons.check_circle,
      ),
      PasswordRequirement(
        text: 'A-Z',
        isValid: password.contains(RegExp(r'[A-Z]')),
        icon: Icons.check_circle,
      ),
      PasswordRequirement(
        text: 'a-z',
        isValid: password.contains(RegExp(r'[a-z]')),
        icon: Icons.check_circle,
      ),
      PasswordRequirement(
        text: '0-9',
        isValid: password.contains(RegExp(r'[0-9]')),
        icon: Icons.check_circle,
      ),
      PasswordRequirement(
        text: '!@#',
        isValid: password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
        icon: Icons.check_circle,
      ),
    ];
  }
  
  @override
  Widget build(BuildContext context) {
    final requirements = _getPasswordRequirements();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Título más elegante
          Row(
            children: [
              Icon(
                Icons.verified_user,
                size: 14,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                'Requisitos de seguridad',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Lista de requisitos más espaciada
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: requirements.asMap().entries.map((entry) {
              final index = entry.key;
              final requirement = entry.value;
              
              return AnimatedBuilder(
                animation: _animations[index],
                builder: (context, child) {
                  return _buildCompactRequirementItem(requirement, index);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  
  Widget _buildCompactRequirementItem(PasswordRequirement requirement, int index) {
    final animationValue = _animations[index].value;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: requirement.isValid 
          ? AppTheme.successColor.withOpacity(0.1)
          : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: requirement.isValid 
            ? AppTheme.successColor.withOpacity(0.4)
            : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icono más profesional
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: requirement.isValid 
                ? AppTheme.successColor.withOpacity(animationValue)
                : Colors.grey.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: requirement.isValid
              ? Icon(
                  Icons.check,
                  size: 8,
                  color: Colors.white,
                )
              : Icon(
                  Icons.circle_outlined,
                  size: 8,
                  color: Colors.grey.shade400,
                ),
          ),
          const SizedBox(width: 6),
          
          // Texto más legible
          Text(
            requirement.text,
            style: TextStyle(
              fontSize: 11,
              color: requirement.isValid 
                ? AppTheme.successColor
                : Colors.grey.shade600,
              fontWeight: requirement.isValid ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
}

/// Clase que representa un requisito de contraseña
class PasswordRequirement {
  final String text;
  final bool isValid;
  final IconData icon;
  
  const PasswordRequirement({
    required this.text,
    required this.isValid,
    required this.icon,
  });
}
