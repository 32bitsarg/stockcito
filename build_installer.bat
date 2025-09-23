@echo off
echo ========================================
echo    CONSTRUCTOR DE INSTALADOR STOCKCITO
echo ========================================
echo.

echo [1/4] Limpiando builds anteriores...
flutter clean
echo ✅ Builds anteriores limpiados

echo.
echo [2/4] Obteniendo dependencias...
flutter pub get
echo ✅ Dependencias obtenidas

echo.
echo [3/4] Construyendo aplicación para Windows...
flutter build windows --release
if %ERRORLEVEL% neq 0 (
    echo ❌ Error al construir la aplicación
    pause
    exit /b 1
)
echo ✅ Aplicación construida

echo.
echo [4/4] Creando instalador...
"C:\Program Files (x86)\NSIS\makensis.exe" installer.nsi
if %ERRORLEVEL% neq 0 (
    echo ❌ Error al crear el instalador
    echo Asegúrate de tener NSIS instalado
    pause
    exit /b 1
)
echo ✅ Instalador creado: stockcito_installer_1.1.0-alpha.1.exe

echo.
echo ========================================
echo    INSTALADOR CREADO EXITOSAMENTE
echo ========================================
echo.
echo El instalador se encuentra en la raíz del proyecto
echo Archivo: stockcito_installer_1.1.0-alpha.1.exe
echo.
pause
