# Apartado: datos del equipo

function Obtener-Equipo {
  $sistema = Get-CimInstance Win32_ComputerSystem
  $bios = Get-CimInstance Win32_BIOS
  $placa = Get-CimInstance Win32_BaseBoard
  $so = Get-CimInstance Win32_OperatingSystem
  $filas = [ordered]@{
    'Fabricante'        = $sistema.Manufacturer
    'Modelo'            = $sistema.Model
    'Número de serie'   = $bios.SerialNumber
    'Placa base'        = "$($placa.Manufacturer) $($placa.Product)"
    'Versión de BIOS'   = $bios.SMBIOSBIOSVersion
    'Sistema operativo' = "$($so.Caption) ($($so.Version))"
  }
  return @{
    Titulo  = 'Equipo'
    Estado  = $null
    Motivos = @('Comprueba que el número de serie coincide con el de la etiqueta de la base del portátil.')
    Cuerpo  = Nueva-Tabla $filas
  }
}
