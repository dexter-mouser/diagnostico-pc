# Apartado: discos (SMART)

function Evaluar-Disco($disco, $contadores) {
  $estados = @()
  $motivos = @()
  $nombre = $disco.FriendlyName
  switch ("$($disco.HealthStatus)") {
    'Healthy'   { $estados += 'verde' }
    'Warning'   { $estados += 'amarillo'; $motivos += "${nombre}: Windows marca el disco con advertencias." }
    'Unhealthy' { $estados += 'rojo'; $motivos += "${nombre}: Windows marca el disco como defectuoso." }
  }
  if ($null -eq $contadores) {
    $estados += 'amarillo'
    $motivos += "${nombre}: no se pudieron leer los datos SMART (ejecuta como administrador)."
    return @{ Estado = Obtener-PeorEstado $estados; Motivos = $motivos }
  }
  $estadoDesgaste = Evaluar-Cantidad $contadores.Wear $DESGASTE_SSD_REVISAR $DESGASTE_SSD_MAL
  if ($estadoDesgaste -eq 'amarillo' -or $estadoDesgaste -eq 'rojo') { $motivos += "${nombre}: desgaste del $($contadores.Wear) %." }
  $estados += $estadoDesgaste
  $errores = [int]$contadores.ReadErrorsUncorrected + [int]$contadores.WriteErrorsUncorrected
  if ($errores -gt 0) { $estados += 'rojo'; $motivos += "${nombre}: $errores errores de lectura o escritura sin corregir." }
  if ($contadores.PowerOnHours -ge $HORAS_DISCO_ALTAS) { $estados += 'amarillo'; $motivos += "${nombre}: más de $HORAS_DISCO_ALTAS horas encendido." }
  return @{ Estado = Obtener-PeorEstado $estados; Motivos = $motivos }
}

function Nueva-FilasDisco($disco, $contadores) {
  $filas = [ordered]@{
    'Modelo'               = $disco.FriendlyName
    'Tipo'                 = "$($disco.MediaType) · $($disco.BusType)"
    'Capacidad'            = "$([math]::Round($disco.Size / 1GB)) GB"
    'Salud según Windows'  = "$($disco.HealthStatus)"
    'Horas encendido'      = $null
    'Veces encendido'      = $null
    'Desgaste'             = $null
    'Temperatura'          = $null
    'Errores sin corregir' = $null
  }
  if (-not $contadores) { return $filas }
  if ($null -ne $contadores.PowerOnHours) { $filas['Horas encendido'] = "$($contadores.PowerOnHours) h (≈ $([math]::Round($contadores.PowerOnHours / 24)) días)" }
  $filas['Veces encendido'] = $contadores.StartStopCycleCount
  if ($null -ne $contadores.Wear) { $filas['Desgaste'] = "$($contadores.Wear) %" }
  if ($contadores.Temperature) { $filas['Temperatura'] = "$($contadores.Temperature) °C" }
  $filas['Errores sin corregir'] = "$([int]$contadores.ReadErrorsUncorrected + [int]$contadores.WriteErrorsUncorrected)"
  return $filas
}

function Obtener-Discos {
  $cuerpo = ''
  $estados = @()
  $motivos = @()
  foreach ($disco in @(Get-PhysicalDisk)) {
    $contadores = $null
    try { $contadores = $disco | Get-StorageReliabilityCounter } catch { }
    $evaluacion = Evaluar-Disco $disco $contadores
    $estados += $evaluacion.Estado
    $motivos += $evaluacion.Motivos
    $cuerpo += "<h3>$(Escapar-Texto $disco.FriendlyName) $(Nuevo-Indicador $evaluacion.Estado)</h3>$(Nueva-Tabla (Nueva-FilasDisco $disco $contadores))"
  }
  return @{ Titulo = 'Discos'; Estado = Obtener-PeorEstado $estados; Motivos = $motivos; Cuerpo = $cuerpo }
}
