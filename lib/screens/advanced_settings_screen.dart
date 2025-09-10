import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/theme_manager_service.dart';
import '../widgets/theme_selector_widget.dart';
import '../widgets/animated_widgets.dart';
import '../config/app_theme.dart';

class AdvancedSettingsScreen extends StatefulWidget {
  const AdvancedSettingsScreen({super.key});

  @override
  State<AdvancedSettingsScreen> createState() => _AdvancedSettingsScreenState();
}

class _AdvancedSettingsScreenState extends State<AdvancedSettingsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Configuración Avanzada'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: FaIcon(FontAwesomeIcons.palette, size: 18),
              text: 'Apariencia',
            ),
            Tab(
              icon: FaIcon(FontAwesomeIcons.gear, size: 18),
              text: 'General',
            ),
            Tab(
              icon: FaIcon(FontAwesomeIcons.info, size: 18),
              text: 'Acerca de',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAppearanceTab(),
          _buildGeneralTab(),
          _buildAboutTab(),
        ],
      ),
    );
  }

  Widget _buildAppearanceTab() {
    return Consumer<ThemeManagerService>(
      builder: (context, themeManager, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Selector de temas
              AnimatedCard(
                delay: const Duration(milliseconds: 100),
                child: const ThemeSelectorWidget(),
              ),
              const SizedBox(height: 24),

              // Vista previa del tema
              AnimatedCard(
                delay: const Duration(milliseconds: 200),
                child: _buildThemePreview(themeManager),
              ),
              const SizedBox(height: 24),

              // Configuración de animaciones
              AnimatedCard(
                delay: const Duration(milliseconds: 300),
                child: _buildAnimationSettings(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGeneralTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Configuración de notificaciones
          AnimatedCard(
            delay: const Duration(milliseconds: 100),
            child: _buildSettingsSection(
              'Notificaciones',
              FontAwesomeIcons.bell,
              [
                _buildSwitchTile(
                  'Notificaciones de stock bajo',
                  'Recibir alertas cuando el stock esté bajo',
                  true,
                ),
                _buildSwitchTile(
                  'Recordatorios de ventas',
                  'Notificaciones diarias de ventas',
                  false,
                ),
                _buildSwitchTile(
                  'Actualizaciones de la app',
                  'Notificaciones sobre nuevas versiones',
                  true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Configuración de datos
          AnimatedCard(
            delay: const Duration(milliseconds: 200),
            child: _buildSettingsSection(
              'Datos',
              FontAwesomeIcons.database,
              [
                _buildActionTile(
                  'Exportar datos',
                  'Guardar una copia de seguridad',
                  FontAwesomeIcons.download,
                  () {},
                ),
                _buildActionTile(
                  'Importar datos',
                  'Restaurar desde una copia de seguridad',
                  FontAwesomeIcons.upload,
                  () {},
                ),
                _buildActionTile(
                  'Limpiar caché',
                  'Liberar espacio de almacenamiento',
                  FontAwesomeIcons.trashCan,
                  () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Información de la app
          AnimatedCard(
            delay: const Duration(milliseconds: 100),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const FaIcon(
                      FontAwesomeIcons.baby,
                      size: 40,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Stockcito',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Versión 1.0.0',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Sistema de gestión de inventario y ventas. Calcula precios, gestiona stock y controla ventas de manera eficiente.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Enlaces útiles
          AnimatedCard(
            delay: const Duration(milliseconds: 200),
            child: _buildSettingsSection(
              'Enlaces Útiles',
              FontAwesomeIcons.link,
              [
                _buildActionTile(
                  'Política de Privacidad',
                  'Cómo protegemos tus datos',
                  FontAwesomeIcons.shield,
                  () {},
                ),
                _buildActionTile(
                  'Términos de Uso',
                  'Condiciones del servicio',
                  FontAwesomeIcons.fileContract,
                  () {},
                ),
                _buildActionTile(
                  'Soporte Técnico',
                  'Obtener ayuda y soporte',
                  FontAwesomeIcons.headset,
                  () {},
                ),
                _buildActionTile(
                  'Calificar App',
                  'Deja tu opinión en la tienda',
                  FontAwesomeIcons.star,
                  () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemePreview(ThemeManagerService themeManager) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vista Previa',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // Simulación de tarjeta con el tema actual
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: themeManager.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: themeManager.primaryColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: themeManager.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.boxesStacked,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Productos',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: themeManager.primaryColor,
                        ),
                      ),
                      const Text(
                        '12 productos en inventario',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimationSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Animaciones',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildSwitchTile(
            'Habilitar animaciones',
            'Activar transiciones suaves en la interfaz',
            true,
          ),
          const SizedBox(height: 12),
          _buildSwitchTile(
            'Animaciones de entrada',
            'Efectos al cargar elementos',
            true,
          ),
          const SizedBox(height: 12),
          _buildSwitchTile(
            'Reducir movimiento',
            'Minimizar animaciones para mejor accesibilidad',
            false,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                FaIcon(
                  icon,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 14,
          color: AppTheme.textSecondary,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: (newValue) {
          // Implementar lógica de cambio
        },
        activeColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: FaIcon(
          icon,
          color: AppTheme.primaryColor,
          size: 16,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 14,
          color: AppTheme.textSecondary,
        ),
      ),
      trailing: const FaIcon(
        FontAwesomeIcons.chevronRight,
        size: 14,
        color: AppTheme.textSecondary,
      ),
    );
  }
}
