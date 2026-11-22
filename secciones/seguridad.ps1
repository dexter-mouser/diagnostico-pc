# Apartado: seguridad del equipo (TPM, arranque seguro, BitLocker, antivirus y Windows 11)

function Obtener-VersionTpm {
  $tpm = Obtener-ListaDispositivos | Where-Object { $_.PNPClass -eq 'SecurityDevices' -and $_.Name -match '\d+\.\d+' } | Select-Object -First 1
  if ($tpm -and $tpm.Name -match '(\d+\.\d+)') { return $Matches[1] }
  return $null
}

# cmd expone el tipo de firmware en %firmware_type%; la clave de Secure Boot solo existe en UEFI
function Obtener-Firmware {
  $rutaArranqueSeguro = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\State'
  $tipoFirmware = "$(cmd /c 'echo %firmware_type%')".Trim()
  $arranqueSeguro = Get-ItemProperty $rutaArranqueSeguro -ErrorAction SilentlyContinue
  return @{
    EsUefi              = $tipoFirmware -eq 'UEFI' -or (Test-Path $rutaArranqueSeguro)
    TieneArranqueSeguro = $arranqueSeguro.UEFISecureBootEnabled -eq 1
  }
}

# Con administrador se lee de BitLocker; si no, del Explorador (menos preciso)
function Obtener-EstadoBitLocker {
  try {
    $volumen = Get-BitLockerVolume -MountPoint $env:SystemDrive -ErrorAction Stop
    if ("$($volumen.ProtectionStatus)" -eq 'On') { return 'Activado' }
    if ("$($volumen.VolumeStatus)" -eq 'FullyDecrypted') { return 'Desactivado' }
    return "$($volumen.VolumeStatus)"
  } catch { }
  try {
    $unidad = (New-Object -ComObject Shell.Application).NameSpace("$env:SystemDrive\")
    $valor = $unidad.Self.ExtendedProperty('System.Volume.BitLockerProtection')
    if ($null -eq $valor) { return $null }
    $texto = $ESTADOS_BITLOCKER[[int]$valor]
    if ($texto) { return $texto }
    return "Sin confirmar (código $valor): míralo en Configuración > Privacidad y seguridad > Cifrado de dispositivo"
  } catch { }
  return $null
}

function Obtener-Antivirus {
  $defensor = $null
  try { $defensor = Get-MpComputerStatus -ErrorAction Stop } catch { }
  $nombres = @()
  try { $nombres = @(Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntiVirusProduct -ErrorAction Stop | ForEach-Object { $_.displayName }) } catch { }
  return @{
    DefenderActivo = $defensor -and $defensor.AntivirusEnabled -and $defensor.RealTimeProtectionEnabled
    Instalados     = $nombres
  }
}

function Obtener-FaltantesWindows11($versionTpm, $firmware) {
  $faltantes = @()
  $ramGb = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
  $discoGb = [math]::Round((Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$env:SystemDrive'").Size / 1GB)
  if (-not $versionTpm -or [double]$versionTpm -lt 2) { $faltantes += 'TPM 2.0' }
  if (-not $firmware.EsUefi) { $faltantes += 'arranque UEFI' }
  if ($ramGb -lt $RAM_MINIMA_WINDOWS_11_GB) { $faltantes += "$RAM_MINIMA_WINDOWS_11_GB GB de RAM" }
  if ($discoGb -lt $DISCO_MINIMO_WINDOWS_11_GB) { $faltantes += "$DISCO_MINIMO_WINDOWS_11_GB GB de disco" }
  return $faltantes
}

function Evaluar-Seguridad($datos) {
  $estados = @('verde')
  $motivos = @()
  if (-not $datos.VersionTpm) { $estados += 'amarillo'; $motivos += 'No se detecta el chip TPM: puede estar desactivado en la BIOS.' }
  if (-not $datos.Firmware.TieneArranqueSeguro) { $estados += 'amarillo'; $motivos += 'El arranque seguro (Secure Boot) está desactivado.' }
  if ($datos.BitLocker -like 'Activado*' -or $datos.BitLocker -eq 'Cifrando') { $estados += 'amarillo'; $motivos += 'El disco está cifrado con BitLocker: pide la clave de recuperación o que lo desactiven antes de comprarlo.' }
  if (-not $datos.Antivirus.DefenderActivo -and $datos.Antivirus.Instalados.Count -le 1) { $estados += 'amarillo'; $motivos += 'La protección antivirus en tiempo real está desactivada.' }
  if ($datos.EsWindows10) { $estados += 'amarillo'; $motivos += 'Tiene Windows 10, que ya no recibe actualizaciones de seguridad gratuitas.' }
  if ($datos.EsWindows10 -and $datos.FaltantesWindows11.Count -gt 0) { $estados += 'rojo'; $motivos += "No puede pasar a Windows 11: le falta $($datos.FaltantesWindows11 -join ', ')." }
  return @{ Estado = Obtener-PeorEstado $estados; Motivos = $motivos }
}

function Obtener-Seguridad {
  $firmware = Obtener-Firmware
  $versionTpm = Obtener-VersionTpm
  $datos = @{
    VersionTpm         = $versionTpm
    Firmware           = $firmware
    BitLocker          = Obtener-EstadoBitLocker
    Antivirus          = Obtener-Antivirus
    EsWindows10        = (Get-CimInstance Win32_OperatingSystem).Caption -match 'Windows 10'
    FaltantesWindows11 = @(Obtener-FaltantesWindows11 $versionTpm $firmware)
  }
  $evaluacion = Evaluar-Seguridad $datos
  $filas = [ordered]@{
    'Chip TPM'                         = $(if ($versionTpm) { "Sí (versión $versionTpm)" } else { 'No detectado' })
    'Arranque UEFI'                    = Convertir-SiNo $firmware.EsUefi
    'Arranque seguro (Secure Boot)'    = Convertir-SiNo $firmware.TieneArranqueSeguro
    'BitLocker en el disco del sistema' = $datos.BitLocker
    'Antivirus de Windows activo'      = Convertir-SiNo $datos.Antivirus.DefenderActivo
    'Antivirus instalados'             = $datos.Antivirus.Instalados -join ', '
    'Requisitos básicos de Windows 11' = $(if ($datos.FaltantesWindows11.Count -eq 0) { 'Cumple (sin revisar el procesador)' } else { "Le falta: $($datos.FaltantesWindows11 -join ', ')" })
  }
  return @{ Titulo = 'Seguridad'; Estado = $evaluacion.Estado; Motivos = $evaluacion.Motivos; Cuerpo = Nueva-Tabla $filas }
}
