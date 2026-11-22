# Apartado: antigüedad aproximada

function Obtener-InstalacionesPrevias {
  $claves = @(Get-ChildItem 'HKLM:\SYSTEM\Setup' -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -like 'Source OS*' })
  $fechas = @()
  foreach ($clave in $claves) {
    $segundos = (Get-ItemProperty $clave.PSPath -ErrorAction SilentlyContinue).InstallDate
    if ($segundos) { $fechas += [DateTimeOffset]::FromUnixTimeSeconds([long]$segundos).LocalDateTime }
  }
  return $fechas
}

function Obtener-WebGarantia($fabricante) {
  foreach ($patron in $WEBS_GARANTIA.Keys) {
    if ($fabricante -match $patron) { return $WEBS_GARANTIA[$patron] }
  }
  return $null
}

function Obtener-FechaPantallaInterna {
  try {
    $pantalla = @(Obtener-Monitores) | Where-Object { $_.EsInterna -and $_.Anio } | Select-Object -First 1
    if ($pantalla) { return Formatear-FabricacionMonitor $pantalla }
  } catch { }
  return $null
}

function Nuevo-TextoGarantia($fabricante, $serie) {
  $web = Obtener-WebGarantia $fabricante
  $textoSerie = Escapar-Texto $serie
  if ($web) {
    return "<p>Fecha real de fabricación y garantía: busca el número de serie <strong>$textoSerie</strong> en <a href=`"$web`" target=`"_blank`" rel=`"noopener`">la web de garantía del fabricante</a>.</p>"
  }
  return "<p>Fecha real de fabricación y garantía: busca el número de serie <strong>$textoSerie</strong> en la web de soporte del fabricante.</p>"
}

function Obtener-Antiguedad {
  $bios = Get-CimInstance Win32_BIOS
  $so = Get-CimInstance Win32_OperatingSystem
  $sistema = Get-CimInstance Win32_ComputerSystem
  $primeraInstalacion = @(@(Obtener-InstalacionesPrevias) + $so.InstallDate) | Sort-Object | Select-Object -First 1
  $eventoMasAntiguo = Get-WinEvent -LogName System -Oldest -MaxEvents 1 -ErrorAction SilentlyContinue
  $horasDisco = $null
  try { $horasDisco = (Get-PhysicalDisk | Get-StorageReliabilityCounter | Measure-Object PowerOnHours -Maximum).Maximum } catch { }
  $filas = [ordered]@{
    'Fecha de la BIOS'                     = Formatear-Fecha $bios.ReleaseDate
    'Fabricación de la pantalla'           = Obtener-FechaPantallaInterna
    'Primera instalación de Windows'       = Formatear-Fecha $primeraInstalacion
    'Instalación actual de Windows'        = Formatear-Fecha $so.InstallDate
    'Evento más antiguo del registro'      = $(if ($eventoMasAntiguo) { Formatear-Fecha $eventoMasAntiguo.TimeCreated } else { $null })
    'Horas de uso del disco (la más alta)' = $(if ($horasDisco) { "$horasDisco h" } else { $null })
  }
  return @{
    Titulo  = 'Antigüedad aproximada'
    Estado  = $null
    Motivos = @('Windows no guarda la fecha de la primera activación. Estas fechas son pistas: la más antigua es la más fiable.')
    Cuerpo  = (Nueva-Tabla $filas) + (Nuevo-TextoGarantia $sistema.Manufacturer $bios.SerialNumber)
  }
}
