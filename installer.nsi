; Script de instalación para Stockcito
; Generado automáticamente para Flutter Windows

!define APP_NAME "Stockcito"
!define APP_VERSION "1.1.0-alpha.1"
!define APP_PUBLISHER "32bitsarg"
!define APP_EXE "stockcito.exe"
!define APP_ICON "stockcito.exe"
!define INSTALL_DIR "$PROGRAMFILES\${APP_NAME}"

; Configuración del instalador
Name "${APP_NAME}"
OutFile "stockcito_installer_${APP_VERSION}.exe"
InstallDir "${INSTALL_DIR}"
InstallDirRegKey HKLM "Software\${APP_NAME}" "Install_Dir"
RequestExecutionLevel admin

; Interfaz del instalador
!include "MUI2.nsh"

; !define MUI_ICON "build\windows\x64\runner\Release\${APP_ICON}"
; !define MUI_UNICON "build\windows\x64\runner\Release\${APP_ICON}"
; !define MUI_HEADERIMAGE
; !define MUI_HEADERIMAGE_BITMAP "header.bmp"
; !define MUI_WELCOMEFINISHPAGE_BITMAP "welcome.bmp"

; Páginas del instalador
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "LICENSE.txt"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

; Páginas de desinstalación
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

; Idiomas
!insertmacro MUI_LANGUAGE "Spanish"

; Sección de instalación
Section "Instalar ${APP_NAME}" SecMain
    SetOutPath "$INSTDIR"
    
    ; Archivo principal
    File "build\windows\x64\runner\Release\stockcito.exe"
    
    ; DLLs de Flutter
    File "build\windows\x64\runner\Release\flutter_windows.dll"
    File "build\windows\x64\runner\Release\pdfium.dll"
    File "build\windows\x64\runner\Release\printing_plugin.dll"
    File "build\windows\x64\runner\Release\screen_retriever_plugin.dll"
    File "build\windows\x64\runner\Release\url_launcher_windows_plugin.dll"
    File "build\windows\x64\runner\Release\window_manager_plugin.dll"
    File "build\windows\x64\runner\Release\app_links_plugin.dll"
    
    ; Carpeta de datos
    SetOutPath "$INSTDIR\data"
    File /r "build\windows\x64\runner\Release\data\*"
    
    ; Crear shortcuts
    CreateDirectory "$SMPROGRAMS\${APP_NAME}"
    CreateShortCut "$SMPROGRAMS\${APP_NAME}\${APP_NAME}.lnk" "$INSTDIR\${APP_EXE}"
    CreateShortCut "$DESKTOP\${APP_NAME}.lnk" "$INSTDIR\${APP_EXE}"
    
    ; Registrar en el sistema
    WriteRegStr HKLM "Software\${APP_NAME}" "Install_Dir" "$INSTDIR"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "DisplayName" "${APP_NAME}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "UninstallString" '"$INSTDIR\uninstall.exe"'
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "DisplayIcon" '"$INSTDIR\${APP_EXE}"'
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "Publisher" "${APP_PUBLISHER}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "DisplayVersion" "${APP_VERSION}"
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "NoModify" 1
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "NoRepair" 1
    
    ; Crear desinstalador
    WriteUninstaller "$INSTDIR\uninstall.exe"
SectionEnd

; Sección de desinstalación
Section "Uninstall"
    ; Eliminar archivos
    Delete "$INSTDIR\${APP_EXE}"
    Delete "$INSTDIR\flutter_windows.dll"
    Delete "$INSTDIR\pdfium.dll"
    Delete "$INSTDIR\printing_plugin.dll"
    Delete "$INSTDIR\screen_retriever_plugin.dll"
    Delete "$INSTDIR\url_launcher_windows_plugin.dll"
    Delete "$INSTDIR\window_manager_plugin.dll"
    Delete "$INSTDIR\app_links_plugin.dll"
    Delete "$INSTDIR\uninstall.exe"
    
    ; Eliminar carpeta de datos
    RMDir /r "$INSTDIR\data"
    RMDir "$INSTDIR"
    
    ; Eliminar shortcuts
    Delete "$SMPROGRAMS\${APP_NAME}\${APP_NAME}.lnk"
    RMDir "$SMPROGRAMS\${APP_NAME}"
    Delete "$DESKTOP\${APP_NAME}.lnk"
    
    ; Eliminar registro
    DeleteRegKey HKLM "Software\${APP_NAME}"
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}"
SectionEnd
