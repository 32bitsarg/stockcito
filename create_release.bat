@echo off
echo ========================================
echo    CREADOR DE RELEASE STOCKCITO
echo ========================================
echo.

set /p VERSION="Ingresa la versión del release (ej: 1.0.1): "
if "%VERSION%"=="" (
    echo ERROR: Debes ingresar una versión
    pause
    exit /b 1
)

set /p NOTES="Ingresa las notas del release (opcional): "

echo.
echo Creando release para versión %VERSION%...
echo.

echo [1/3] Verificando que existe el instalador...
if not exist "stockcito_installer_%VERSION%.exe" (
    echo ERROR: No se encontró stockcito_installer_%VERSION%.exe
    echo Ejecuta primero build_installer.bat
    pause
    exit /b 1
)
echo ✅ Instalador encontrado

echo [2/3] Creando tag de Git...
git tag -a "v%VERSION%" -m "Release %VERSION%"
if %errorlevel% neq 0 (
    echo ERROR: Falló la creación del tag
    pause
    exit /b 1
)
echo ✅ Tag creado: v%VERSION%

echo [3/3] Subiendo tag a GitHub...
git push origin "v%VERSION%"
if %errorlevel% neq 0 (
    echo ERROR: Falló el push del tag
    pause
    exit /b 1
)
echo ✅ Tag subido a GitHub

echo.
echo ========================================
echo    RELEASE CREADO EXITOSAMENTE
echo ========================================
echo.
echo Tag: v%VERSION%
echo Archivo: stockcito_installer_%VERSION%.exe
echo.
echo Ahora ve a GitHub y crea el release manualmente:
echo 1. Ve a https://github.com/32bitsarg/stockcito/releases
echo 2. Haz clic en "Create a new release"
echo 3. Selecciona el tag v%VERSION%
echo 4. Sube el archivo stockcito_installer_%VERSION%.exe
echo 5. Agrega las notas: %NOTES%
echo.
pause
