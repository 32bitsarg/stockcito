@echo off
echo ========================================
echo    ACTUALIZADOR DE VERSIÓN STOCKCITO
echo ========================================
echo.

set /p NEW_VERSION="Ingresa la nueva versión (ej: 1.0.2): "
if "%NEW_VERSION%"=="" (
    echo ERROR: Debes ingresar una versión
    pause
    exit /b 1
)

echo.
echo Actualizando versión a %NEW_VERSION%...
echo.

echo [1/3] Actualizando installer.nsi...
powershell -Command "(Get-Content installer.nsi) -replace '!define APP_VERSION \"[^\"]*\"', '!define APP_VERSION \"%NEW_VERSION%\"' | Set-Content installer.nsi"
echo ✅ installer.nsi actualizado

echo [2/3] Actualizando build_installer.bat...
powershell -Command "(Get-Content build_installer.bat) -replace 'stockcito_installer_[^\"]*\.exe', 'stockcito_installer_%NEW_VERSION%.exe' | Set-Content build_installer.bat"
echo ✅ build_installer.bat actualizado

echo [3/3] Actualizando pubspec.yaml...
powershell -Command "(Get-Content pubspec.yaml) -replace 'version: [^\"]*', 'version: %NEW_VERSION%+1' | Set-Content pubspec.yaml"
echo ✅ pubspec.yaml actualizado

echo.
echo ========================================
echo    VERSIÓN ACTUALIZADA A %NEW_VERSION%
echo ========================================
echo.
echo Ahora puedes ejecutar build_installer.bat para crear el instalador
echo.
pause
