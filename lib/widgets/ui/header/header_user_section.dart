import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../services/auth/supabase_auth_service.dart';
import '../../../screens/auth/login_screen.dart';

/// Widget para la sección de usuario del header
class HeaderUserSection extends StatelessWidget {
  final bool showUserInfo;
  final VoidCallback? onLogout;

  const HeaderUserSection({
    super.key,
    this.showUserInfo = true,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return _buildUserInfo(context);
  }

  Widget _buildUserInfo(BuildContext context) {
    return _buildLogoutTextButton(context);
  }


  Widget _buildLogoutTextButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showLogoutDialog(context),
        borderRadius: BorderRadius.circular(8),
        hoverColor: AppTheme.errorColor.withOpacity(0.05),
        splashColor: AppTheme.errorColor.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Padding más compacto
          decoration: BoxDecoration(
            color: AppTheme.errorColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(6), // Border radius más pequeño
            border: Border.all(
              color: AppTheme.errorColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.logout,
                color: AppTheme.errorColor,
                size: 12, // Icono más pequeño
              ),
              const SizedBox(width: 4), // Espaciado más pequeño
              Text(
                'Cerrar Sesión',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 11, // Texto más pequeño
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: AppTheme.surfaceColor,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.logout,
                  color: AppTheme.errorColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Cerrar Sesión',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            '¿Estás seguro de que quieres cerrar sesión?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Cerrar diálogo
                
                // Ejecutar callback personalizado si existe
                onLogout?.call();
                
                // O usar el servicio de autenticación por defecto
                if (onLogout == null) {
                  final authService = SupabaseAuthService();
                  await authService.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text(
                'Cerrar Sesión',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }
}
