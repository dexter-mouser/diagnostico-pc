# Apartado: autenticidad del procesador
# Windows toma el nombre del procesador del registro, que se puede cambiar.
# El firmware (SMBIOS) guarda su propio nombre y número de núcleos, que no dependen de Windows.

# Recorre la tabla SMBIOS hasta la estructura de tipo 4 (procesador)
function Obtener-ProcesadorSmbios {
  $datos = (Get-CimInstance -Namespace root\wmi -ClassName MSSmBios_RawSMBiosTables | Select-Object -First 1).SMBiosData
  $posicion = 0
  while ($posicion + 4 -le $datos.Length) {
    $tipo = $datos[$posicion]
    $largo = $datos[$posicion + 1]
    if ($largo -lt 4 -or $tipo -eq 127) { break }
    $inicioCadenas = $posicion + $largo
    $fin = $inicioCadenas
    while ($fin + 1 -lt $datos.Length -and -not ($datos[$fin] -eq 0 -and $datos[$fin + 1] -eq 0)) { $fin++ }
    if ($tipo -eq 4) {
      $cadenas = [Text.Encoding]::ASCII.GetString($datos, $inicioCadenas, $fin - $inicioCadenas).Split([char]0)
      $indiceNombre = $datos[$posicion + 0x10]
      return @{
        Nombre  = $(if ($indiceNombre -gt 0 -and $indiceNombre -le $cadenas.Count) { $cadenas[$indiceNombre - 1].Trim() } else { $null })
        Nucleos = $(if ($largo -gt 0x23) { [int]$datos[$posicion + 0x23] } else { $null })
        Hilos   = $(if ($largo -gt 0x25) { [int]$datos[$posicion + 0x25] } else { $null })
      }
    }
    $posicion = $fin + 2
  }
  return $null
}

function Obtener-ModeloProcesador($nombre) {
  if ("$nombre" -match $PATRON_MODELO_PROCESADOR) { return ($Matches[0] -replace '\s+', ' ').ToLower() }
  return $null
}

# Busca comandos que reescriban el nombre del procesador al arrancar
function Buscar-CambioNombreProcesador {
  $indicios = @()
  try {
    foreach ($tarea in Get-ScheduledTask -ErrorAction Stop) {
      $acciones = ($tarea.Actions | ForEach-Object { "$($_.Execute) $($_.Arguments)" }) -join ' '
      if ($acciones -match $PATRON_CAMBIO_PROCESADOR) { $indicios += "Tarea programada: $($tarea.TaskName)" }
    }
  } catch { }
  $claves = @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run', 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce', 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run', 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce')
  foreach ($clave in $claves) {
    $valores = Get-ItemProperty $clave -ErrorAction SilentlyContinue
    if (-not $valores) { continue }
    foreach ($propiedad in $valores.PSObject.Properties | Where-Object { $_.Name -notlike 'PS*' }) {
      if ("$($propiedad.Value)" -match $PATRON_CAMBIO_PROCESADOR) { $indicios += "Programa de arranque: $($propiedad.Name)" }
    }
  }
  $carpetasInicio = @([Environment]::GetFolderPath('Startup'), [Environment]::GetFolderPath('CommonStartup'))
  foreach ($archivo in Get-ChildItem $carpetasInicio -File -Include *.bat, *.cmd, *.ps1, *.reg, *.vbs -Recurse -ErrorAction SilentlyContinue) {
    if (Select-String -Path $archivo.FullName -Pattern $PATRON_CAMBIO_PROCESADOR -Quiet) { $indicios += "Archivo de inicio: $($archivo.Name)" }
  }
  return @($indicios | Sort-Object -Unique)
}

function Evaluar-Procesador($datos) {
  $estados = @('verde')
  $motivos = @()
  $modeloWindows = Obtener-ModeloProcesador $datos.NombreWindows
  $modeloFirmware = Obtener-ModeloProcesador $datos.Firmware.Nombre
  if ($modeloWindows -and $modeloFirmware -and $modeloWindows -ne $modeloFirmware) {
    $estados += 'rojo'
    $motivos += "Windows dice «$($datos.NombreWindows)» pero el firmware dice «$($datos.Firmware.Nombre)»: el nombre está falsificado."
  }
  if ($datos.NombreRegistro -and $datos.NombreRegistro.Trim() -ne $datos.NombreWindows.Trim()) {
    $estados += 'amarillo'
    $motivos += 'El nombre del registro no coincide con el que informa Windows.'
  }
  if ($datos.Firmware.Nucleos -and $datos.Firmware.Nucleos -ne $datos.Nucleos) {
    $estados += 'amarillo'
    $motivos += "El firmware indica $($datos.Firmware.Nucleos) núcleos y Windows $($datos.Nucleos)."
  }
  if ($datos.Cambios.Count -gt 0) {
    $estados += 'rojo'
    $motivos += 'Hay programas que cambian el nombre del procesador al arrancar Windows.'
  }
  if (-not $datos.Firmware.Nombre) { $estados += 'gris'; $motivos += 'No se pudo leer el nombre del procesador desde el firmware.' }
  return @{ Estado = Obtener-PeorEstado $estados; Motivos = $motivos }
}

function Obtener-Procesador {
  $procesador = @(Get-CimInstance Win32_Processor)[0]
  $firmware = $null
  try { $firmware = Obtener-ProcesadorSmbios } catch { }
  if (-not $firmware) { $firmware = @{ Nombre = $null; Nucleos = $null; Hilos = $null } }
  $datos = @{
    NombreWindows  = "$($procesador.Name)".Trim()
    NombreRegistro = (Get-ItemProperty 'HKLM:\HARDWARE\DESCRIPTION\System\CentralProcessor\0' -ErrorAction SilentlyContinue).ProcessorNameString
    Nucleos        = [int]$procesador.NumberOfCores
    Hilos          = [int]$procesador.NumberOfLogicalProcessors
    Firmware       = $firmware
    Cambios        = Buscar-CambioNombreProcesador
  }
  $evaluacion = Evaluar-Procesador $datos
  $filas = [ordered]@{
    'Nombre según Windows'           = $datos.NombreWindows
    'Nombre según el firmware'       = $firmware.Nombre
    'Núcleos e hilos según Windows'  = "$($datos.Nucleos) / $($datos.Hilos)"
    'Núcleos e hilos según firmware' = $(if ($firmware.Nucleos) { "$($firmware.Nucleos) / $($firmware.Hilos)" } else { $null })
    'Velocidad base'                 = "$([math]::Round($procesador.MaxClockSpeed / 1000, 2)) GHz"
    'Programas que cambian el nombre' = $(if ($datos.Cambios.Count -gt 0) { $datos.Cambios -join ', ' } else { 'Ninguno' })
  }
  $cuerpo = (Nueva-Tabla $filas) + '<p>Para una tercera opinión, CPU-Z lee el procesador directamente del chip.</p>'
  return @{ Titulo = 'Autenticidad del procesador'; Estado = $evaluacion.Estado; Motivos = $evaluacion.Motivos; Cuerpo = $cuerpo }
}
