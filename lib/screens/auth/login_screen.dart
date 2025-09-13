import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/auth/supabase_auth_service.dart';
import '../../services/auth/auth_error_handler.dart';
import '../../services/auth/security_service.dart';
import '../../services/system/consent_manager_service.dart';
import '../../services/system/logging_service.dart';
import 'register_screen.dart';
import '../dashboard/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final SupabaseAuthService _authService = SupabaseAuthService();
  final ConsentManagerService _consentManager = ConsentManagerService();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    // Verificar si el usuario está bloqueado
    final isBlocked = await SecurityService().isUserBlocked();
    if (isBlocked) {
      final remainingTime = await SecurityService().getRemainingBlockTimeMinutes();
      setState(() {
        _errorMessage = 'Demasiados intentos fallidos. Intenta nuevamente en $remainingTime minutos.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      if (success && mounted) {
        // Mostrar consentimiento después del login
        await _consentManager.checkAndShowConsentIfNeeded(context);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      } else {
        setState(() {
          _errorMessage = 'Credenciales inválidas';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.toString());
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInAnonymously() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await _authService.signInAnonymously();
      
      if (success && mounted) {
        // Mostrar consentimiento después del login anónimo
        await _consentManager.checkAndShowConsentIfNeeded(context);
        
        // Cargar datos existentes del usuario anónimo si los hay
        await _loadAnonymousUserData();
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      } else {
        setState(() {
          _errorMessage = 'Error al iniciar sesión anónima';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al iniciar sesión anónima: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Carga datos existentes del usuario anónimo
  Future<void> _loadAnonymousUserData() async {
    try {
      // Los datos del usuario anónimo se cargarán automáticamente
      // cuando DatosService detecte que hay una sesión anónima activa
      LoggingService.info('Cargando datos del usuario anónimo...');
    } catch (e) {
      LoggingService.error('Error cargando datos anónimos: $e');
    }
  }

  // Google Sign-In temporalmente deshabilitado

  String _getErrorMessage(String error) {
    return AuthErrorHandler.getErrorMessage(error);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calcular el espacio disponible para distribuir
            final availableHeight = constraints.maxHeight;
            
            // Determinar si es una pantalla muy pequeña
            final isVerySmall = availableHeight < 500;
            final isSmall = availableHeight < 600;
            
            // Ajustar padding y espaciado según el espacio disponible
            final padding = isVerySmall ? 8.0 : (isSmall ? 12.0 : 16.0);
            final logoSize = isVerySmall ? 40.0 : (isSmall ? 50.0 : 60.0);
            final titleSize = isVerySmall ? 20.0 : (isSmall ? 24.0 : 28.0);
            final subtitleSize = isVerySmall ? 12.0 : (isSmall ? 14.0 : 16.0);
            
            // Calcular espaciado dinámico
            final totalPadding = padding * 2;
            final availableContentHeight = availableHeight - totalPadding;
            final headerHeight = logoSize + 20 + titleSize + 8 + subtitleSize + 20; // Logo + espacios + títulos
            final formHeight = 200; // Altura estimada del formulario
            final linksHeight = 120; // Altura estimada de enlaces y botones
            final totalContentHeight = headerHeight + formHeight + linksHeight;
            
            // Si el contenido no cabe, reducir espaciado
            final needsCompression = totalContentHeight > availableContentHeight;
            final dynamicSpacing = needsCompression ? 8.0 : 16.0;
            
            return Container(
              width: double.infinity,
              height: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: padding * 0.3, vertical: padding),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Formulario a la izquierda
                    SizedBox(
                      width: 400,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildCompactLoginForm(isVerySmall),
                          SizedBox(height: dynamicSpacing),
                          _buildCompactLinks(isVerySmall, dynamicSpacing),
                        ],
                      ),
                    ),
                    
                    // Espacio entre secciones
                    const SizedBox(width: 80),
                    
                    // Header animado a la derecha
                    SizedBox(
                      width: 350,
                      child: _buildAnimatedHeader(logoSize, titleSize, subtitleSize),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader(double logoSize, double titleSize, double subtitleSize) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(50 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo animado más grande con múltiples animaciones
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1500),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, logoValue, child) {
                      return Transform.scale(
                        scale: 0.7 + (0.3 * logoValue),
                        child: Transform.rotate(
                          angle: (1 - logoValue) * -0.8,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - logoValue)),
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 1500),
                              width: logoSize * 2,
                              height: logoSize * 2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.primaryColor.withOpacity(0.8 + (0.2 * logoValue)),
                                    AppTheme.secondaryColor.withOpacity(0.8 + (0.2 * logoValue)),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20 + (5 * logoValue)),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withOpacity(0.4 * logoValue),
                                    blurRadius: 20 + (20 * logoValue),
                                    offset: Offset(0, 8 + (4 * logoValue)),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: TweenAnimationBuilder<double>(
                                  duration: const Duration(milliseconds: 2000),
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  builder: (context, textValue, child) {
                                    return Transform.scale(
                                      scale: 0.5 + (0.5 * textValue),
                                      child: Opacity(
                                        opacity: textValue,
                                        child: Text(
                                          'S',
                                          style: TextStyle(
                                            fontSize: 48 + (8 * textValue),
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white.withOpacity(0.8 + (0.2 * textValue)),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 20 * value),
                  
                  // Título animado más grande con efectos avanzados
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1800),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, titleValue, child) {
                      return Transform.translate(
                        offset: Offset(-40 * (1 - titleValue), 10 * (1 - titleValue)),
                        child: Transform.scale(
                          scale: 0.8 + (0.2 * titleValue),
                          child: Opacity(
                            opacity: titleValue,
                            child: AnimatedDefaultTextStyle(
                              duration: Duration(milliseconds: 1800),
                              style: TextStyle(
                                fontSize: (titleSize * 1.5) + (5 * titleValue),
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary.withOpacity(0.7 + (0.3 * titleValue)),
                                letterSpacing: 1 + (2 * titleValue),
                              ),
                              child: Text(
                                'Stockcito',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 8 * value),
                  
                  // Subtítulo animado más grande con efectos de escritura
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 2200),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, subtitleValue, child) {
                      return Transform.translate(
                        offset: Offset(-25 * (1 - subtitleValue), 5 * (1 - subtitleValue)),
                        child: Transform.scale(
                          scale: 0.9 + (0.1 * subtitleValue),
                          child: Opacity(
                            opacity: subtitleValue,
                            child: AnimatedDefaultTextStyle(
                              duration: Duration(milliseconds: 2200),
                              style: TextStyle(
                                fontSize: (subtitleSize * 1.2) + (2 * subtitleValue),
                                color: AppTheme.textSecondary.withOpacity(0.6 + (0.4 * subtitleValue)),
                                height: 1.5,
                                letterSpacing: 0.5 + (0.5 * subtitleValue),
                              ),
                              child: Text(
                                'Gestiona tu inventario\nde manera inteligente',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 24 * value),
                  
                  // Características adicionales con animación escalonada avanzada
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 2000),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, featuresValue, child) {
                      return Transform.translate(
                        offset: Offset(-20 * (1 - featuresValue), 10 * (1 - featuresValue)),
                        child: Opacity(
                          opacity: featuresValue,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _buildAnimatedFeatureItem(Icons.analytics, 'Control total de inventario', 0),
                              const SizedBox(height: 8),
                              _buildAnimatedFeatureItem(Icons.psychology, 'Análisis inteligente con IA', 1),
                              const SizedBox(height: 8),
                              _buildAnimatedFeatureItem(Icons.devices, 'Acceso desde cualquier dispositivo', 2),
                              const SizedBox(height: 8),
                              _buildAnimatedFeatureItem(Icons.security, 'Datos seguros y encriptados', 3),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildAnimatedFeatureItem(IconData icon, String text, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 2500 + (index * 300)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(-15 * (1 - value), 5 * (1 - value)),
          child: Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Opacity(
              opacity: value,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 1000),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, iconValue, child) {
                      return Transform.rotate(
                        angle: (1 - iconValue) * 0.3,
                        child: Icon(
                          icon,
                          size: 20 + (2 * iconValue),
                          color: AppTheme.primaryColor.withOpacity(0.7 + (0.3 * iconValue)),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  AnimatedDefaultTextStyle(
                    duration: Duration(milliseconds: 1500),
                    style: TextStyle(
                      fontSize: 16 + (1 * value),
                      color: AppTheme.textSecondary.withOpacity(0.6 + (0.4 * value)),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5 * value,
                    ),
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(width: 12),
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Iniciar Sesión',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Campo de email
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'tu@email.com',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa tu email';
                }
                if (!value.contains('@')) {
                  return 'Ingresa un email válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            
            // Campo de contraseña
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                hintText: 'Tu contraseña',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa tu contraseña';
                }
                if (value.length < 6) {
                  return 'La contraseña debe tener al menos 6 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 28),
            
            // Mensaje de error
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Botón de login
            ElevatedButton(
              onPressed: _isLoading ? null : _signInWithEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Iniciar Sesión',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            
            const SizedBox(height: 16),
            
            // Divider
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 1,
                    color: AppTheme.borderColor,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'o',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    color: AppTheme.borderColor,
                  ),
                ),
              ],
            ),
            
            // Google Sign-In temporalmente deshabilitado
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿No tienes cuenta? ',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const RegisterScreen()),
            );
          },
          child: Text(
            'Regístrate aquí',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: AppTheme.textSecondary.withOpacity(0.2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'o',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: AppTheme.textSecondary.withOpacity(0.2),
          ),
        ),
      ],
    );
  }

  Widget _buildAnonymousButton() {
    return Column(
      children: [
        OutlinedButton(
          onPressed: _isLoading ? null : _signInAnonymously,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.textPrimary,
            side: BorderSide(color: AppTheme.textSecondary.withOpacity(0.3)),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_outline, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Continuar como invitado',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Modo Invitado',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Los datos se guardarán solo localmente. Para sincronizar con la nube, crea una cuenta.',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: 12,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Métodos compactos para pantallas pequeñas
  Widget _buildCompactHeader(double logoSize, double titleSize, double subtitleSize) {
    return Column(
      children: [
        // Logo compacto
        Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(logoSize * 0.2),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: logoSize * 0.2,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'S',
              style: TextStyle(
                fontSize: logoSize * 0.5,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        SizedBox(height: logoSize * 0.3),
        
        // Título compacto
        Text(
          'Iniciar Sesión',
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: titleSize * 0.3),
        
        // Subtítulo compacto
        Text(
          'Bienvenido de vuelta a Stockcito',
          style: TextStyle(
            fontSize: subtitleSize,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactLoginForm(bool isVerySmall) {
    return Container(
      width: isVerySmall ? 300 : 400,
      padding: EdgeInsets.all(isVerySmall ? 20 : 32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(isVerySmall ? 16 : 20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: isVerySmall ? 20 : 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Campo de email
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: isVerySmall ? 12 : 16,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa tu email';
                }
                if (!value.contains('@')) {
                  return 'Por favor ingresa un email válido';
                }
                return null;
              },
            ),
            SizedBox(height: isVerySmall ? 12 : 16),
            
            // Campo de contraseña
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: isVerySmall ? 12 : 16,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa tu contraseña';
                }
                if (value.length < 6) {
                  return 'La contraseña debe tener al menos 6 caracteres';
                }
                return null;
              },
            ),
            SizedBox(height: isVerySmall ? 16 : 24),
            
            // Botón de login
            SizedBox(
              height: isVerySmall ? 44 : 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signInWithEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Iniciar Sesión',
                        style: TextStyle(
                          fontSize: isVerySmall ? 14 : 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            
            // Mensaje de error
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: isVerySmall ? 11 : 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactLinks(bool isVerySmall, double spacing) {
    return Column(
      children: [
        // Enlace a registro
        TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const RegisterScreen()),
            );
          },
          child: Text(
            '¿No tienes cuenta? Regístrate aquí',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontSize: isVerySmall ? 12 : 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        
        SizedBox(height: spacing),
        
        // Divider
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                color: AppTheme.borderColor,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'o',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: isVerySmall ? 11 : 12,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                color: AppTheme.borderColor,
              ),
            ),
          ],
        ),
        
        SizedBox(height: spacing),
        
        // Botón de sesión anónima
        SizedBox(
          height: isVerySmall ? 40 : 44,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _signInAnonymously,
            icon: Icon(
              Icons.person_outline,
              size: isVerySmall ? 16 : 18,
            ),
            label: Text(
              'Continuar como Invitado',
              style: TextStyle(
                fontSize: isVerySmall ? 12 : 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: BorderSide(color: AppTheme.primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        
        SizedBox(height: spacing),
        
        // Tooltip permanente para modo invitado
        _buildPermanentTooltip(isVerySmall),
      ],
    );
  }

  Widget _buildPermanentTooltip(bool isVerySmall) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isVerySmall ? 8 : 16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Contenedor principal del tooltip
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isVerySmall ? 12 : 16,
              vertical: isVerySmall ? 8 : 12,
            ),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.blue.shade200,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono de información
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: isVerySmall ? 14 : 16,
                  ),
                ),
                SizedBox(width: isVerySmall ? 8 : 12),
                
                // Texto del tooltip
                Flexible(
                  child: Text(
                    'Modo invitado: datos locales únicamente',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: isVerySmall ? 11 : 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                SizedBox(width: isVerySmall ? 8 : 12),
                
                // Indicador de tooltip (flecha)
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ),
          
          // Punto de conexión del tooltip (línea vertical)
          Positioned(
            left: isVerySmall ? 20 : 24,
            bottom: -8,
            child: Container(
              width: 2,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.blue.shade200,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
