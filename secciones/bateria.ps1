# Apartado: batería

function Evaluar-Bateria($salud, $ciclos) {
  $estados = @()
  $motivos = @()
  if ($null -eq $salud) { $estados += 'gris' }
  elseif ($salud -ge $SALUD_BATERIA_BIEN) { $estados += 'verde' }
  elseif ($salud -ge $SALUD_BATERIA_REVISAR) { $estados += 'amarillo'; $motivos += "La batería conserva el $salud % de su capacidad original." }
  else { $estados += 'rojo'; $motivos += "La batería conserva solo el $salud % de su capacidad original: habrá que cambiarla." }
  if ($ciclos -ge $CICLOS_BATERIA_ALTOS) { $estados += 'amarillo'; $motivos += "La batería tiene $ciclos ciclos de carga." }
  return @{ Estado = Obtener-PeorEstado $estados; Motivos = $motivos }
}

function Obtener-Bateria($carpetaInforme) {
  if (@(Get-CimInstance Win32_Battery).Count -eq 0) {
    return @{ Titulo = 'Batería'; Estado = 'rojo'; Motivos = @('No se detecta batería: puede estar desconectada o muerta.'); Cuerpo = '' }
  }
  $rutaXml = Join-Path $env:TEMP 'diagnostico-bateria.xml'
  powercfg /batteryreport /xml /output $rutaXml | Out-Null
  powercfg /batteryreport /output (Join-Path $carpetaInforme 'bateria.html') | Out-Null
  $xml = New-Object xml
  $xml.Load($rutaXml)
  Remove-Item $rutaXml -ErrorAction SilentlyContinue
  $cuerpo = ''
  $estados = @()
  $motivos = @()
  foreach ($bateria in @($xml.BatteryReport.Batteries.Battery)) {
    $diseno = [double]$bateria.DesignCapacity
    $actual = [double]$bateria.FullChargeCapacity
    $ciclos = [int]$bateria.CycleCount
    $salud = $null
    if ($diseno -gt 0) { $salud = [math]::Round($actual / $diseno * 100) }
    $evaluacion = Evaluar-Bateria $salud $ciclos
    $estados += $evaluacion.Estado
    $motivos += $evaluacion.Motivos
    $filas = [ordered]@{
      'Fabricante y modelo' = "$($bateria.Manufacturer) $($bateria.Id)"
      'Capacidad original'  = "$diseno mWh"
      'Capacidad actual'    = "$actual mWh"
      'Salud'               = $(if ($null -ne $salud) { "$salud %" } else { $null })
      'Ciclos de carga'     = $(if ($ciclos -gt 0) { $ciclos } else { 'El equipo no lo informa' })
    }
    $cuerpo += Nueva-Tabla $filas
  }
  $cuerpo += '<p>Informe completo de Windows con el historial de uso: <a href="bateria.html">bateria.html</a></p>'
  return @{ Titulo = 'Batería'; Estado = Obtener-PeorEstado $estados; Motivos = $motivos; Cuerpo = $cuerpo }
}
