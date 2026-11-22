# Apartado: licencia de Windows y bloqueos de empresa

function Obtener-UnionCorporativa {
  $sistema = Get-CimInstance Win32_ComputerSystem
  $estaEnAzure = $null -ne (dsregcmd /status | Select-String 'AzureAdJoined\s*:\s*YES')
  return @{ Dominio = [bool]$sistema.PartOfDomain; Azure = $estaEnAzure; NombreDominio = $sistema.Domain }
}

function Obtener-Licencia {
  $filtro = "ApplicationID='$ID_APLICACION_WINDOWS' AND PartialProductKey IS NOT NULL"
  $producto = @(Get-CimInstance SoftwareLicensingProduct -Filter $filtro) | Select-Object -First 1
  $servicio = Get-CimInstance SoftwareLicensingService
  $union = Obtener-UnionCorporativa
  $estados = @()
  $motivos = @()
  $estaActivado = $producto -and $producto.LicenseStatus -eq 1
  $canal = $null
  if ($producto -and $producto.Description -match ',\s*(\S+)\s+channel') { $canal = $Matches[1] }
  if ($estaActivado) { $estados += 'verde' } else { $estados += 'rojo'; $motivos += 'Windows no está activado.' }
  if ($canal -like 'VOLUME*') { $estados += 'amarillo'; $motivos += 'Licencia corporativa por volumen: puede dejar de funcionar fuera de la empresa.' }
  if ($union.Dominio -or $union.Azure) { $estados += 'rojo'; $motivos += 'El equipo está unido a una empresa: pide que lo liberen antes de comprarlo.' }
  $claveBios = $servicio.OA3xOriginalProductKey
  $filas = [ordered]@{
    'Estado'                             = $(if ($estaActivado) { 'Activado' } else { 'No activado' })
    'Edición'                            = $(if ($producto) { $producto.Name } else { $null })
    'Tipo de licencia'                   = $canal
    'Clave de Windows en la BIOS'        = $(if ($claveBios) { "Sí (termina en $($claveBios.Substring($claveBios.Length - 5)))" } else { 'No' })
    'Unido a un dominio'                 = $(if ($union.Dominio) { "Sí ($($union.NombreDominio))" } else { 'No' })
    'Unido a Microsoft Entra (Azure AD)' = Convertir-SiNo $union.Azure
  }
  return @{ Titulo = 'Licencia y bloqueos'; Estado = Obtener-PeorEstado $estados; Motivos = $motivos; Cuerpo = Nueva-Tabla $filas }
}
