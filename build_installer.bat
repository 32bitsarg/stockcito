@echo off
echo ========================================
echo    CONSTRUCTOR DE INSTALADOR STOCKCITO
echo ========================================
echo.

echo [1/4] Construyendo aplicación Flutter...
call flutter build windows --release
if %errorlevel% neq 0 (
    echo ERROR: Falló la construcción de Flutter
    pause
    exit /b 1
)
echo ✅ Aplicación construida exitosamente
echo.

echo [2/4] Verificando archivos de release...
if not exist "build\windows\x64\runner\Release\stockcito.exe" (
    echo ERROR: No se encontró stockcito.exe
    pause
    exit /b 1
)
echo ✅ Archivos de release encontrados
echo.

echo [3/4] Compilando instalador NSIS...
"C:\Program Files (x86)\NSIS\makensis.exe" installer.nsi
if %errorlevel% neq 0 (
    echo ERROR: Falló la compilación del instalador
    pause
    exit /b 1
)
echo ✅ Instalador compilado exitosamente
echo.

echo [4/4] Verificando instalador...
if exist "stockcito_installer_1.0.1.exe" (
    echo ✅ Instalador creado: stockcito_installer_1.0.1.exe
    for %%I in (stockcito_installer_1.0.1.exe) do echo    Tamaño: %%~zI bytes
) else (
    echo ERROR: No se encontró el instalador generado
    pause
    exit /b 1
)

echo.
echo ========================================
echo    INSTALADOR STOCKCITO CREADO EXITOSAMENTE
echo ========================================
echo.
echo El instalador está listo para distribución.
echo Ubicación: %cd%\stockcito_installer_1.0.1.exe
echo.
pause
