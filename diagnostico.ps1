# Diagnóstico de un portátil de segunda mano: genera un informe HTML con el estado del equipo.
#Requires -Version 5.1

$ErrorActionPreference = 'Stop'
$RAIZ = $PSScriptRoot

# Carga del núcleo y de los apartados
foreach ($archivo in @(Get-ChildItem (Join-Path $RAIZ 'nucleo\*.ps1')) + @(Get-ChildItem (Join-Path $RAIZ 'secciones\*.ps1'))) {
  . $archivo.FullName
}

function Nueva-CarpetaInforme {
  $serie = "$((Get-CimInstance Win32_BIOS).SerialNumber)" -replace '[^\w-]', ''
  if (-not $serie) { $serie = 'equipo' }
  $carpeta = Join-Path $RAIZ "informes\$serie-$((Get-Date).ToString('yyyyMMdd-HHmm'))"
  New-Item -ItemType Directory -Force -Path $carpeta | Out-Null
  return $carpeta
}

# Arranque
Write-Host 'Analizando el equipo, puede tardar un minuto...'
$esAdministrador = Probar-EsAdministrador
$carpetaInforme = Nueva-CarpetaInforme
$secciones = @(
  (Invocar-Seccion 'Equipo' { Obtener-Equipo })
  (Invocar-Seccion 'Componentes' { Obtener-Componentes })
  (Invocar-Seccion 'Pantalla' { Obtener-Pantalla })
  (Invocar-Seccion 'Dispositivos' { Obtener-Dispositivos })
  (Invocar-Seccion 'Discos' { Obtener-Discos })
  (Invocar-Seccion 'Batería' { Obtener-Bateria $carpetaInforme })
  (Invocar-Seccion 'Antigüedad aproximada' { Obtener-Antiguedad })
  (Invocar-Seccion 'Licencia y bloqueos' { Obtener-Licencia })
  (Invocar-Seccion 'Seguridad' { Obtener-Seguridad })
  (Invocar-Seccion 'Programas' { Obtener-Programas })
  (Invocar-Seccion 'Actualizaciones' { Obtener-Actualizaciones })
  (Invocar-Seccion 'Errores registrados' { Obtener-Errores })
  (Obtener-RevisionManual)
  (Obtener-PruebasExternas)
)
$rutaInforme = Join-Path $carpetaInforme 'informe.html'
$codificacion = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllText($rutaInforme, (Nueva-Pagina $secciones $esAdministrador), $codificacion)
Write-Host "Informe guardado en: $rutaInforme"
if (-not $env:DIAGNOSTICO_SIN_ABRIR) { Start-Process $rutaInforme }
