# Apartado: licencia de Windows, activadores piratas y bloqueos de empresa

function Obtener-UnionCorporativa {
  $sistema = Get-CimInstance Win32_ComputerSystem
  $estaEnAzure = $null -ne (dsregcmd /status | Select-String 'AzureAdJoined\s*:\s*YES')
  return @{ Dominio = [bool]$sistema.PartOfDomain; Azure = $estaEnAzure; NombreDominio = $sistema.Domain }
}

# Busca rastros de activadores: servidor KMS fijado, archivos, gancho de KMS_VL_ALL, tareas y servicios
function Buscar-Activadores($producto, $servicio) {
  $indicios = @()
  $servidorKms = @($servicio.KeyManagementServiceMachine, $producto.KeyManagementServiceMachine) | Where-Object { $_ } | Select-Object -First 1
  if ($servidorKms) { $indicios += "Servidor de activación KMS fijado a mano: $servidorKms" }
  foreach ($ruta in $RUTAS_ACTIVADORES) {
    $rutaReal = [Environment]::ExpandEnvironmentVariables($ruta)
    if (Test-Path $rutaReal) { $indicios += "Archivo de activador: $rutaReal" }
  }
  $gancho = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\SppExtComObj.exe'
  if ((Get-ItemProperty $gancho -ErrorAction SilentlyContinue).VerifierDlls) { $indicios += 'Gancho de activación en SppExtComObj.exe (KMS_VL_ALL)' }
  try {
    $indicios += Get-ScheduledTask -ErrorAction Stop | Where-Object { $_.TaskPath -notlike '\Microsoft\*' -and $_.TaskName -match $PATRON_ACTIVADORES } | ForEach-Object { "Tarea programada: $($_.TaskName)" }
  } catch { }
  $indicios += Get-CimInstance Win32_Service | Where-Object { "$($_.Name) $($_.DisplayName) $($_.PathName)" -match $PATRON_ACTIVADORES } | ForEach-Object { "Servicio: $($_.DisplayName)" }
  return @($indicios | Sort-Object -Unique)
}

function Evaluar-Licencia($datos) {
  $estados = @()
  $motivos = @()
  if ($datos.EstaActivado) { $estados += 'verde' } else { $estados += 'rojo'; $motivos += 'Windows no está activado.' }
  $esEmpresa = $datos.Union.Dominio -or $datos.Union.Azure
  if ($datos.Activadores.Count -gt 0) {
    $estados += 'rojo'
    $motivos += 'Windows parece activado con un activador pirata: la activación puede perderse y estos programas suelen traer malware.'
  } elseif ($datos.Canal -like 'VOLUME_KMS*' -and -not $esEmpresa) {
    $estados += 'rojo'
    $motivos += 'Activación KMS en un equipo que no es de empresa: casi siempre es una activación pirata.'
  } elseif ($datos.Canal -like 'VOLUME*') {
    $estados += 'amarillo'
    $motivos += 'Licencia corporativa por volumen: puede dejar de funcionar fuera de la empresa.'
  }
  if ($esEmpresa) { $estados += 'rojo'; $motivos += 'El equipo está unido a una empresa: pide que lo liberen antes de comprarlo.' }
  return @{ Estado = Obtener-PeorEstado $estados; Motivos = $motivos }
}

function Obtener-Licencia {
  $filtro = "ApplicationID='$ID_APLICACION_WINDOWS' AND PartialProductKey IS NOT NULL"
  $producto = @(Get-CimInstance SoftwareLicensingProduct -Filter $filtro) | Select-Object -First 1
  $servicio = Get-CimInstance SoftwareLicensingService
  $canal = $null
  if ($producto -and $producto.Description -match ',\s*(\S+)\s+channel') { $canal = $Matches[1] }
  $datos = @{
    EstaActivado = $producto -and $producto.LicenseStatus -eq 1
    Canal        = $canal
    Union        = Obtener-UnionCorporativa
    Activadores  = Buscar-Activadores $producto $servicio
  }
  $evaluacion = Evaluar-Licencia $datos
  $claveBios = $servicio.OA3xOriginalProductKey
  $filas = [ordered]@{
    'Estado'                             = $(if ($datos.EstaActivado) { 'Activado' } else { 'No activado' })
    'Edición'                            = $(if ($producto) { $producto.Name } else { $null })
    'Tipo de licencia'                   = $canal
    'Clave de Windows en la BIOS'        = $(if ($claveBios) { "Sí (termina en $($claveBios.Substring($claveBios.Length - 5)))" } else { 'No' })
    'Unido a un dominio'                 = $(if ($datos.Union.Dominio) { "Sí ($($datos.Union.NombreDominio))" } else { 'No' })
    'Unido a Microsoft Entra (Azure AD)' = Convertir-SiNo $datos.Union.Azure
    'Rastros de activadores piratas'     = $(if ($datos.Activadores.Count -gt 0) { "$($datos.Activadores.Count) encontrado(s)" } else { 'Ninguno' })
  }
  $cuerpo = (Nueva-Tabla $filas) + (Nueva-Lista $datos.Activadores 'lista-larga')
  return @{ Titulo = 'Licencia y bloqueos'; Estado = $evaluacion.Estado; Motivos = $evaluacion.Motivos; Cuerpo = $cuerpo }
}
