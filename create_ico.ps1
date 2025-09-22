# Script para crear archivo ICO con múltiples tamaños
# Requiere .NET Framework

Add-Type -AssemblyName System.Drawing

# Crear un nuevo archivo ICO
$icoPath = "windows\runner\resources\app_icon.ico"

# Lista de archivos PNG a incluir (ordenados por tamaño)
$pngFiles = @(
    "windows\runner\resources\app_icon_16.png",
    "windows\runner\resources\app_icon_32.png", 
    "windows\runner\resources\app_icon_48.png",
    "windows\runner\resources\app_icon_150.png",
    "windows\runner\resources\app_icon_256.png"
)

# Crear una lista de imágenes
$images = @()

foreach ($pngFile in $pngFiles) {
    if (Test-Path $pngFile) {
        $img = [System.Drawing.Image]::FromFile((Resolve-Path $pngFile))
        $images += $img
        Write-Host "✅ Agregado: $pngFile ($($img.Width)x$($img.Height))"
    } else {
        Write-Host "❌ No encontrado: $pngFile"
    }
}

if ($images.Count -gt 0) {
    # Crear el archivo ICO
    $ico = [System.Drawing.Icon]::FromHandle($images[0].GetHicon())
    
    # Guardar como ICO
    $ico.Save($icoPath)
    
    Write-Host "🎉 Archivo ICO creado: $icoPath"
    Write-Host "📊 Tamaños incluidos: $($images.Count)"
    
    # Limpiar recursos
    foreach ($img in $images) {
        $img.Dispose()
    }
    $ico.Dispose()
} else {
    Write-Host "❌ No se encontraron archivos PNG para crear el ICO"
}
