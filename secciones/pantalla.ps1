# Apartado: pantalla (modelo del panel, tamaño, fabricación y modo actual)

function Nueva-FilasMonitor($monitor) {
  return [ordered]@{
    'Fabricante y modelo' = "$($monitor.Fabricante) $($monitor.Nombre) $($monitor.Codigo)" -replace '\s+', ' '
    'Tamaño'              = $(if ($monitor.Pulgadas) { "$($monitor.Pulgadas) pulgadas" } else { $null })
    'Fabricación'         = Formatear-FabricacionMonitor $monitor
  }
}

function Nueva-FilasModoActual {
  $grafica = @(Get-CimInstance Win32_VideoController) | Where-Object { $_.CurrentHorizontalResolution } | Select-Object -First 1
  if (-not $grafica) { return $null }
  return [ordered]@{
    'Resolución' = "$($grafica.CurrentHorizontalResolution) × $($grafica.CurrentVerticalResolution)"
    'Frecuencia' = "$($grafica.CurrentRefreshRate) Hz"
  }
}

# La pantalla pudo cambiarse si se fabricó bastante después que la BIOS
function Probar-PantallaCambiada($monitor) {
  $fechaBios = (Get-CimInstance Win32_BIOS).ReleaseDate
  if (-not $monitor.EsInterna -or -not $monitor.Anio -or -not $fechaBios) { return $false }
  return ($monitor.Anio - ([datetime]$fechaBios).Year) -ge $ANIOS_DIFERENCIA_PANTALLA
}

function Obtener-Pantalla {
  $cuerpo = ''
  $estados = @()
  $motivos = @()
  foreach ($monitor in @(Obtener-Monitores)) {
    $titulo = $(if ($monitor.EsInterna) { 'Pantalla integrada' } else { 'Pantalla externa' })
    $cuerpo += "<h3>$titulo</h3>$(Nueva-Tabla (Nueva-FilasMonitor $monitor))"
    if (Probar-PantallaCambiada $monitor) {
      $estados += 'amarillo'
      $motivos += "La pantalla se fabricó en $($monitor.Anio), bastante después que la BIOS: probablemente se cambió."
    } elseif ($monitor.EsInterna) {
      $estados += 'verde'
    }
  }
  $modoActual = Nueva-FilasModoActual
  if ($modoActual) { $cuerpo += "<h3>Modo actual</h3>$(Nueva-Tabla $modoActual)" }
  $motivos += 'Compara el tamaño y la resolución con los del anuncio.'
  return @{ Titulo = 'Pantalla'; Estado = Obtener-PeorEstado $estados; Motivos = $motivos; Cuerpo = $cuerpo }
}
