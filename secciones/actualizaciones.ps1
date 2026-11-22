# Apartado: actualizaciones de Windows y de la BIOS

function Obtener-UltimaActualizacion {
  return @(Get-HotFix | Where-Object { $_.InstalledOn }) | Sort-Object InstalledOn -Descending | Select-Object -First 1
}

function Obtener-VersionWindows {
  $version = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
  return "$($version.DisplayVersion) (compilación $($version.CurrentBuild).$($version.UBR))"
}

function Obtener-Actualizaciones {
  $ultima = Obtener-UltimaActualizacion
  $bios = Get-CimInstance Win32_BIOS
  $motivos = @()
  $diasSinActualizar = $null
  if ($ultima) { $diasSinActualizar = [int]((Get-Date) - $ultima.InstalledOn).TotalDays }
  $estado = Evaluar-Cantidad $diasSinActualizar $DIAS_SIN_ACTUALIZAR_REVISAR $DIAS_SIN_ACTUALIZAR_MAL
  if ($estado -eq 'amarillo' -or $estado -eq 'rojo') { $motivos += "Windows lleva $diasSinActualizar días sin instalar actualizaciones." }
  if ($bios.ReleaseDate -and ([datetime]$bios.ReleaseDate) -lt (Get-Date).AddYears(-$ANIOS_BIOS_ANTIGUA)) {
    $motivos += "La BIOS tiene más de $ANIOS_BIOS_ANTIGUA años: busca si hay una versión nueva en la web del fabricante."
  }
  $filas = [ordered]@{
    'Versión de Windows'        = Obtener-VersionWindows
    'Última actualización'      = $(if ($ultima) { "$($ultima.HotFixID) del $(Formatear-Fecha $ultima.InstalledOn)" } else { $null })
    'Días sin actualizar'       = $diasSinActualizar
    'Versión de BIOS'           = $bios.SMBIOSBIOSVersion
    'Fecha de la BIOS'          = Formatear-Fecha $bios.ReleaseDate
  }
  return @{ Titulo = 'Actualizaciones'; Estado = $estado; Motivos = $motivos; Cuerpo = Nueva-Tabla $filas }
}
