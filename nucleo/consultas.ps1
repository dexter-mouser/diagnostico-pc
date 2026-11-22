# Consultas al sistema que usan varios apartados

# Convierte los textos de WmiMonitorID (listas de números) en texto
function Convertir-TextoMonitor($codigos) {
  if (-not $codigos) { return $null }
  return (-join ($codigos | Where-Object { $_ -ne 0 } | ForEach-Object { [char]$_ })).Trim()
}

function Obtener-Monitores {
  $identificadores = @(Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorID)
  $medidas = @(Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorBasicDisplayParams -ErrorAction SilentlyContinue)
  $conexiones = @(Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorConnectionParams -ErrorAction SilentlyContinue)
  foreach ($monitor in $identificadores) {
    $medida = $medidas | Where-Object { $_.InstanceName -eq $monitor.InstanceName } | Select-Object -First 1
    $conexion = $conexiones | Where-Object { $_.InstanceName -eq $monitor.InstanceName } | Select-Object -First 1
    $pulgadas = $null
    if ($medida -and $medida.MaxHorizontalImageSize -gt 0) {
      $diagonalCm = [math]::Sqrt([math]::Pow($medida.MaxHorizontalImageSize, 2) + [math]::Pow($medida.MaxVerticalImageSize, 2))
      $pulgadas = [math]::Round($diagonalCm / 2.54, 1)
    }
    [pscustomobject]@{
      Fabricante = Convertir-TextoMonitor $monitor.ManufacturerName
      Nombre     = Convertir-TextoMonitor $monitor.UserFriendlyName
      Codigo     = Convertir-TextoMonitor $monitor.ProductCodeID
      Anio       = $monitor.YearOfManufacture
      Semana     = $monitor.WeekOfManufacture
      Pulgadas   = $pulgadas
      EsInterna  = $conexion -and ($CONEXIONES_PANTALLA_INTERNA -contains [long]$conexion.VideoOutputTechnology)
    }
  }
}

# La semana 0 significa que el fabricante solo indicó el año
function Formatear-FabricacionMonitor($monitor) {
  if (-not $monitor.Anio) { return $null }
  if (-not $monitor.Semana) { return "$($monitor.Anio)" }
  return "Semana $($monitor.Semana) de $($monitor.Anio)"
}

function Obtener-ListaDispositivos {
  return @(Get-CimInstance Win32_PnPEntity)
}
