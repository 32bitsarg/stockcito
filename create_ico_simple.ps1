# Script simple para crear archivo ICO
Add-Type -AssemblyName System.Drawing

$icoPath = "windows\runner\resources\app_icon.ico"
$pngFiles = @(
    "windows\runner\resources\app_icon_16.png",
    "windows\runner\resources\app_icon_32.png", 
    "windows\runner\resources\app_icon_48.png",
    "windows\runner\resources\app_icon_150.png",
    "windows\runner\resources\app_icon_256.png"
)

$images = @()
foreach ($pngFile in $pngFiles) {
    if (Test-Path $pngFile) {
        $img = [System.Drawing.Image]::FromFile((Resolve-Path $pngFile))
        $images += $img
        Write-Host "Agregado: $pngFile"
    }
}

if ($images.Count -gt 0) {
    $ico = [System.Drawing.Icon]::FromHandle($images[0].GetHicon())
    $ico.Save($icoPath)
    Write-Host "Archivo ICO creado: $icoPath"
    
    foreach ($img in $images) {
        $img.Dispose()
    }
    $ico.Dispose()
} else {
    Write-Host "No se encontraron archivos PNG"
}
